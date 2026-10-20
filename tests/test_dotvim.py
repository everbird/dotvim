"""Compatibility and installer smoke tests using only Python's standard library."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
EDITOR = shutil.which(os.environ.get('DOTVIM_TEST_EDITOR', 'vim'))


def vim_string(value):
    return "'" + str(value).replace("'", "''") + "'"


class Workspace(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='dotvim-test-')
        self.addCleanup(self.temporary.cleanup)
        self.scratch = Path(self.temporary.name)
        self.environment = dict(os.environ, DOTVIM_HOME=str(self.scratch / 'home'),
                                XDG_CONFIG_HOME=str(self.scratch / 'config'),
                                XDG_DATA_HOME=str(self.scratch / 'data'),
                                XDG_STATE_HOME=str(self.scratch / 'state'),
                                XDG_CACHE_HOME=str(self.scratch / 'cache'),
                                NVIM_LOG_FILE=str(self.scratch / 'nvim.log'))

    def copy_configuration(self, destination):
        destination.mkdir(parents=True)
        for name in ['vimrc', 'gvimrc', 'init.vim', 'plugins.vim', 'lsp.vim', 'bootstrap.sh']:
            shutil.copy2(ROOT / name, destination / name)
        for name in ['autoload', 'colors', 'snippets', 'nvim', 'scripts']:
            shutil.copytree(ROOT / name, destination / name)
        return destination


@unittest.skipUnless(EDITOR, 'Set DOTVIM_TEST_EDITOR to a Vim or Neovim executable')
class EditorTests(Workspace):
    def run_editor(self, body, profile='basic', checkout=ROOT, settings='', environment=None,
                   native_browser=False, tool_path=None):
        version = subprocess.check_output([EDITOR, '--version'], text=True)
        is_nvim = 'NVIM' in version
        # Vim 7.4's bundled netrw uses silent! unmaps which behave differently
        # inside try/catch and leave a nonzero batch exit status even on success.
        legacy_netrw = native_browser and 'VIM - Vi IMproved 7.4' in version
        result = self.scratch / 'result'
        script = self.scratch / 'check.vim'
        script.write_text('''
function! Check(condition, message) abort
    if !a:condition
        throw a:message
    endif
endfunction
''' + ('' if legacy_netrw else 'try\n') + '''
    call Check(empty(v:errmsg), 'Startup: ' . v:errmsg)
''' + body + '''
    call Check(empty(v:errmsg), 'Runtime: ' . v:errmsg)
    call writefile(['ok'], $DOTVIM_TEST_RESULT)
''' + ('' if legacy_netrw else '''catch
    call writefile([v:exception, v:throwpoint, v:errmsg], $DOTVIM_TEST_RESULT)
    cquit
endtry
''') + '''
qa!
''')
        initial = ('let g:dotvim_state_dir=' + vim_string(self.scratch / 'editor-state')
                   + ' | let g:dotvim_local_config=' + vim_string(self.scratch / 'no-local')
                   + ' | let g:netrw_home=' + vim_string(self.scratch)
                   + " | let g:dotvim_snippets=0 | let g:dotvim_lsp=0 | let v:errmsg=''"
                   + (' | ' + settings if settings else ''))
        if tool_path is not None:
            # Homebrew's Vim launcher needs shell utilities before Vim starts.
            initial = 'let $PATH=' + vim_string(tool_path) + ' | ' + initial
        arguments = [EDITOR, '-n', '-i', 'NONE', '-u', str(checkout / ('init.vim' if is_nvim else 'vimrc')),
                     '--cmd', initial, '-S', str(script)]
        arguments[1:1] = ['--headless'] if is_nvim else ['-N', '-U', 'NONE', '-es']
        env = dict(self.environment, DOTVIM_PROFILE=profile, DOTVIM_TEST_RESULT=str(result))
        env.update(environment or {})
        process = subprocess.run(arguments, env=env, capture_output=True, text=True, timeout=30)
        details = result.read_text() if result.exists() else 'No result was written.'
        self.assertIn(process.returncode, [0, 1] if legacy_netrw else [0],
                      details + process.stdout + process.stderr)
        self.assertEqual(details, 'ok\n', details + process.stdout + process.stderr)

    def test_basic_with_installed_plugins(self):
        self.run_editor('''
    call Check(empty(g:dotvim_loaded_plugins), 'Basic loaded optional plugins')
    call Check(!exists('g:loaded_plug'), 'Basic loaded the plugin manager')
    call Check(!exists('g:loaded_surround'), 'Surround loaded in basic mode')
    call Check(maparg(',ve', 'n') =~# 'dotvim_root', 'Configuration mapping lost')
    call Check(maparg('<C-p>', 'n') =~# 'find', 'Native file lookup missing')
    new sample.py
    call Check(&filetype ==# 'python' && &shiftwidth == 2, 'Python indentation changed')
    execute 'source ' . fnameescape(g:dotvim_root . '/vimrc')
    call Check(&shiftwidth == 2, 'Reload changed Python indentation')
    new sample.yaml
    call Check(&filetype ==# 'yaml' && &shiftwidth == 2, 'YAML indentation changed')
    DotvimHealth
''')

    def test_fresh_checkout_and_repeat_source(self):
        checkout = self.copy_configuration(self.scratch / "checkout with spaces and 'quote'")
        self.run_editor('''
    let before_path = &runtimepath
    let before_ignore = &wildignore
    let before_list = &list
    redir => before_commands
    silent autocmd dotvim
    redir END
    execute 'source ' . fnameescape(g:dotvim_root . '/vimrc')
    execute 'source ' . fnameescape(g:dotvim_root . '/vimrc')
    redir => after_commands
    silent autocmd dotvim
    redir END
    call Check(before_path ==# &runtimepath, 'Runtime paths accumulated')
    call Check(before_ignore ==# &wildignore && before_list == &list, 'Options changed on reload')
    call Check(before_commands ==# after_commands, 'Autocommands accumulated')
''', checkout=checkout)

    def test_full_without_downloads(self):
        checkout = self.copy_configuration(self.scratch / 'no plugins')
        self.run_editor('''
    call Check(empty(g:dotvim_loaded_plugins), 'Unexpected plugin loaded')
    call Check(!empty(g:dotvim_skipped_plugins), 'Missing plugins not explained')
    call dotvim#optional('TagbarToggle', 'Tagbar')
    call dotvim#optional('UndotreeToggle', 'Undotree')
''', profile='full', checkout=checkout)

    def test_full_without_manager(self):
        checkout = self.copy_configuration(self.scratch / 'no manager')
        (checkout / 'autoload/plug.vim').unlink()
        self.run_editor('''
    call Check(empty(g:dotvim_loaded_plugins), 'Plugins loaded without the manager')
    call Check(g:dotvim_skipped_plugins[0] =~# 'vim-plug', 'Missing manager not explained')
    call Check(!exists('g:loaded_plug'), 'Loaded a manager from elsewhere')
''', profile='full', checkout=checkout)

    def test_full_with_plugins_disabled(self):
        self.run_editor('''
    call Check(!exists('g:loaded_plug'), '--noplugin loaded the manager')
    call Check(empty(g:dotvim_loaded_plugins), '--noplugin loaded plugins')
''', profile='full', settings='set noloadplugins')

    def test_unwritable_state_directory(self):
        blocker = self.scratch / 'not a directory'
        blocker.write_text('keep this file')
        self.run_editor('call Check(&number, "Basic options missing")',
                        settings='let g:dotvim_state_dir=' + vim_string(blocker / 'state'))
        self.assertEqual(blocker.read_text(), 'keep this file')

    def test_native_directory_browser(self):
        project = self.scratch / 'directory with spaces'
        project.mkdir()
        (project / 'sample.txt').write_text('sample\n')
        self.run_editor('''
    execute 'cd ' . fnameescape(''' + vim_string(project) + ''')
    doautocmd VimEnter
    call dotvim#browse(0)
    let found = 0
    for number in range(1, bufnr('$'))
        if bufwinnr(number) > 0 && getbufvar(number, '&filetype') ==# 'netrw'
            let found = 1
        endif
    endfor
    call Check(found, 'Native directory browser did not open')
    if exists(':Lexplore') == 2
        call dotvim#browse(0)
        call Check(!exists('t:netrw_lexbufnr'), 'Native sidebar did not close')
    endif
    " Some bundled netrw versions leave E31 after harmless silent! unmaps.
    if v:errmsg =~# '^E31:'
        let v:errmsg = ''
    endif
''', native_browser=True)

    def test_native_search_and_cleanup(self):
        project = self.scratch / 'project'
        project.mkdir()
        (project / 'sample.txt').write_text('unique_dotvim_needle\n')
        empty_path = self.scratch / 'empty-bin'
        empty_path.mkdir()
        self.run_editor('''
    execute 'cd ' . fnameescape(''' + vim_string(project) + ''')
    call dotvim#grep('unique_dotvim_needle')
    call Check(len(getqflist()) == 1, 'Native search did not populate quickfix')
    cclose
    enew!
    call setline(1, ['first  ', '', '', '', 'last\t'])
    let @/ = 'preserve_search'
    call cursor(1, 2)
    call dotvim#clean()
    call Check(getline(1, '$') ==# ['first', '', 'last'], 'Whitespace cleanup failed')
    call Check(@/ ==# 'preserve_search' && col('.') == 2, 'Cleanup changed search or cursor')
''', tool_path=str(empty_path))

    @unittest.skipUnless((ROOT / 'plugged/surround/plugin/surround.vim').exists(),
                         'Plugins have not been installed with vim-plug')
    def test_full_plugins_and_shared_manager(self):
        self.run_editor('''
    call Check(exists('g:loaded_surround'), 'Surround plugin did not load')
    call Check(exists(':NERDTreeToggle') == 2, 'File tree plugin did not load')
    call Check(exists(':UndotreeToggle') == 2, 'Undo tree plugin did not load')
    call Check(g:dotvim_package_loader ==# 'vim-plug', 'Wrong loader')
    enew
    call setline(1, 'hello')
    normal ysiw]
    call Check(getline(1) ==# '[hello]', 'Surround editing failed')
    execute 'source ' . fnameescape(g:dotvim_root . '/vimrc')
    call Check(exists(':NERDTreeToggle') == 2, 'Plugin lost on reload')
''', profile='full')

    def test_full_without_external_tools(self):
        empty_path = self.scratch / 'empty-bin'
        empty_path.mkdir()
        self.run_editor('''
    for name in ['fugitive', 'tagbar', 'fzf', 'fzf-vim', 'undotree', 'ultisnips', 'lsp']
        call Check(index(g:dotvim_loaded_plugins, name) < 0, 'Loaded unavailable feature: ' . name)
    endfor
    call Check(!exists(':Git') && !exists(':TagbarToggle'), 'Unavailable commands were loaded')
    call Check(len(g:plugs) == 13, 'Disabled plugins disappeared from the manifest')
    for name in ['tagbar', 'fzf', 'fzf-vim', 'ultisnips', 'lsp']
        call Check(get(g:plugs[name], 'on', ['unexpected']) ==# [], 'Unavailable plugin was not disabled')
    endfor
''', profile='full', tool_path=str(empty_path))

    def test_startup_does_not_download(self):
        git = shutil.which('git')
        if not git:
            self.skipTest('Git is not installed')
        commands = self.scratch / 'bin'
        commands.mkdir()
        wrapper = commands / 'git'
        wrapper.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$DOTVIM_GIT_LOG"\nexec '
                           + "'" + git.replace("'", "'\\''") + "'" + ' "$@"\n')
        wrapper.chmod(0o755)
        log = self.scratch / 'git-log'
        checkout = self.copy_configuration(self.scratch / 'no downloads')
        self.run_editor('call Check(exists(":PlugInstall") == 2, "vim-plug commands missing")',
                        profile='full', checkout=checkout,
                        environment={'PATH': str(commands) + os.pathsep + os.environ['PATH'],
                                     'DOTVIM_GIT_LOG': str(log)})
        calls = log.read_text() if log.exists() else ''
        self.assertNotRegex(calls, r'\b(clone|fetch|pull|ls-remote)\b')
        self.assertFalse((checkout / 'plugged').exists())

    @unittest.skipUnless(shutil.which('rg'), 'ripgrep is not installed')
    def test_ripgrep_search(self):
        project = self.scratch / 'project'
        project.mkdir()
        (project / 'file with spaces.txt').write_text('needle with "quotes"\n')
        self.run_editor('''
    execute 'cd ' . fnameescape(''' + vim_string(project) + ''')
    let saved_format = &errorformat
    call dotvim#grep('needle with "quotes"')
    call Check(len(getqflist()) == 1 && getqflist()[0].lnum == 1, 'ripgrep search failed')
    call Check(&errorformat ==# saved_format, 'Search changed errorformat')
    cclose
''')

    def test_python_path_quoting(self):
        interpreter = self.scratch / "python with 'quote'"
        interpreter.write_text('#!/bin/sh\nprintf "%s\\n" "$1" > "$DOTVIM_PYTHON_LOG"\n')
        interpreter.chmod(0o755)
        sample = self.scratch / "script with %#! and 'quote'.py"
        sample.write_text('pass\n')
        log = self.scratch / 'python-log'
        self.run_editor('''
    execute 'edit ' . fnameescape(''' + vim_string(sample) + ''')
    call dotvim#python()
''', settings='let g:dotvim_python=' + vim_string(interpreter),
                        environment={'DOTVIM_PYTHON_LOG': str(log)})
        self.assertEqual(log.read_text().strip(), str(sample))

    def test_available_enhanced_tools(self):
        if not (ROOT / 'plugged/fzf-vim/plugin/fzf.vim').exists():
            self.skipTest('Plugins are not installed with vim-plug')
        self.run_editor('''
    if index(g:dotvim_loaded_plugins, 'fzf-vim') >= 0
        call Check(exists(':Files') == 2, 'fzf file command missing')
        call Check(executable(fzf#exec()), 'fzf executable not resolved')
    endif
    if index(g:dotvim_loaded_plugins, 'tagbar') >= 0
        call Check(exists(':TagbarToggle') == 2, 'Tagbar command missing')
    endif
''', profile='full')

    def test_lsp_without_servers(self):
        self.run_editor(r'''
    call Check(g:dotvim_lsp_status =~# '0 available\|requires\|disabled\|not installed', 'Unexpected LSP status')
''', profile='full', settings='let g:dotvim_lsp=1 | let g:dotvim_lsp_servers=[]')

    def test_optional_snippet_engine(self):
        self.run_editor('''
    if index(g:dotvim_loaded_plugins, 'ultisnips') >= 0
        call Check(exists(':UltiSnipsEdit') == 2, 'Snippet engine did not initialize: ' . string(get(g:, 'UltiSnipsPythonDiagnostics', [])))
    endif
''', profile='full', settings='let g:dotvim_snippets=1')

    def test_local_settings_and_final_overrides(self):
        local = self.scratch / 'local.vim'
        local.write_text("let g:dotvim_colorscheme='missing_dotvim_test_theme'\n"
                         'function! DotvimLocal() abort\n    set nocursorcolumn\nendfunction\n')
        self.run_editor('''
    call Check(!&cursorcolumn, 'Final local override was ignored')
    call Check(g:colors_name ==# 'desert', 'Missing theme did not fall back')
''', settings='let g:dotvim_local_config=' + vim_string(local))

    def test_lsp_handshake(self):
        version = subprocess.check_output([EDITOR, '--version'], text=True)
        nvim_version = re.search(r'NVIM v(\d+)\.(\d+)', version)
        vim_version = re.search(r'VIM - Vi IMproved (\d+)\.', version)
        if not ((nvim_version and tuple(map(int, nvim_version.groups())) >= (0, 11))
                or (vim_version and int(vim_version[1]) >= 9)):
            self.skipTest('LSP requires Vim 9+ or Neovim 0.11+')
        if not (ROOT / 'plugged/lsp/plugin/lsp.vim').exists() and 'NVIM' not in version:
            self.skipTest('Vim LSP plugin is not installed')
        project = self.scratch / 'lsp-project'
        project.mkdir()
        (project / '.git').mkdir()
        sample = project / 'sample.py'
        sample.write_text('value = 1\n')
        log = self.scratch / 'lsp-log'
        server = {'name': 'test', 'cmd': [sys.executable, str(ROOT / 'tests/lsp_server.py')],
                  'filetypes': ['python'], 'root_markers': ['.git']}
        settings = 'let g:dotvim_lsp=1 | let g:dotvim_lsp_servers=[' + str(server) + ']'
        self.run_editor('''
    doautocmd VimEnter
    execute 'edit ' . fnameescape(''' + vim_string(sample) + ''')
    let attempts = 0
    while attempts < 250 && (!filereadable($DOTVIM_LSP_LOG) || join(readfile($DOTVIM_LSP_LOG), '') !~# 'textDocument/didOpen')
        sleep 20m
        let attempts += 1
    endwhile
    call Check(filereadable($DOTVIM_LSP_LOG), 'LSP server was not started')
    call Check(join(readfile($DOTVIM_LSP_LOG), '') =~# 'textDocument/didOpen', 'LSP handshake did not open the document')
''', profile='full', settings=settings, environment={'DOTVIM_LSP_LOG': str(log)})


class InstallerTests(Workspace):
    def setUp(self):
        super().setUp()
        self.checkout = self.copy_configuration(self.scratch / "checkout with spaces and 'quote'")
        self.install_home = Path(self.environment['DOTVIM_HOME'])
        self.install_home.mkdir()
        if EDITOR:
            self.environment['DOTVIM_INSTALL_EDITOR'] = EDITOR

    def install(self, *arguments, success=True, environment=None):
        env = dict(self.environment)
        env.update(environment or {})
        result = subprocess.run(['/bin/sh', str(self.checkout / 'bootstrap.sh'), *arguments],
                                env=env, capture_output=True, text=True, timeout=30)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_backup_and_idempotence(self):
        (self.install_home / '.vim').mkdir()
        (self.install_home / '.vim' / 'keep').write_text('vim data')
        (self.install_home / '.vimrc').symlink_to('missing-original-config')
        nvim = Path(self.environment['XDG_CONFIG_HOME']) / 'nvim'
        nvim.mkdir(parents=True)
        (nvim / 'init.lua').write_text('-- existing Neovim configuration')
        self.install()
        backups = list((self.install_home / '.dotvim-backups').iterdir())
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / 'vim' / 'keep').read_text(), 'vim data')
        self.assertEqual(os.readlink(backups[0] / 'vimrc'), 'missing-original-config')
        self.assertTrue((backups[0] / 'nvim' / 'init.lua').exists())
        self.assertTrue((self.install_home / '.vim').samefile(self.checkout))
        self.assertTrue(nvim.samefile(self.checkout))
        self.install()
        self.assertEqual(list((self.install_home / '.dotvim-backups').iterdir()), backups)
        self.assertEqual((self.install_home / '.dotvim-profile').read_text(), 'basic\n')

    def test_basic_install_without_git_or_editors(self):
        commands = self.scratch / 'bin'
        commands.mkdir()
        for name in ['dirname', 'mktemp', 'touch', 'mkdir', 'mv', 'date', 'ln', 'readlink', 'cmp', 'cp', 'rm']:
            (commands / name).symlink_to(shutil.which(name))
        self.install('--vim-only', environment={'PATH': str(commands)})
        self.assertTrue((self.install_home / '.vimrc').is_symlink())
        self.assertFalse((Path(self.environment['XDG_CONFIG_HOME']) / 'nvim').exists())

    def test_rollback_after_failed_link(self):
        (self.install_home / '.vim').mkdir()
        (self.install_home / '.vim' / 'keep').write_text('original data')
        (self.install_home / '.vimrc').write_text('original vimrc')
        commands = self.scratch / 'bin'
        commands.mkdir()
        fake_ln = commands / 'ln'
        fake_ln.write_text('#!/bin/sh\ncase "$3" in */.vimrc) exit 1;; esac\nexec '
                           + str(shutil.which('ln')) + ' "$@"\n')
        fake_ln.chmod(0o755)
        self.install(success=False, environment={'PATH': str(commands) + os.pathsep + os.environ['PATH']})
        self.assertEqual((self.install_home / '.vim' / 'keep').read_text(), 'original data')
        self.assertEqual((self.install_home / '.vimrc').read_text(), 'original vimrc')
        self.assertFalse((self.install_home / '.dotvim-profile').exists())

    def test_failed_download_keeps_configuration(self):
        (self.install_home / '.vimrc').write_text('original vimrc')
        commands = self.scratch / 'bin'
        commands.mkdir()
        fake_git = commands / 'git'
        fake_git.write_text('#!/bin/sh\nexit 1\n')
        fake_git.chmod(0o755)
        self.install('--full', success=False,
                     environment={'PATH': str(commands) + os.pathsep + os.environ['PATH']})
        self.assertEqual((self.install_home / '.vimrc').read_text(), 'original vimrc')
        self.assertFalse((self.install_home / '.dotvim-backups').exists())

    def test_full_requires_an_editor_before_replacing_configuration(self):
        (self.install_home / '.vimrc').write_text('original vimrc')
        self.install('--full', success=False,
                     environment={'DOTVIM_INSTALL_EDITOR': str(self.scratch / 'missing-editor')})
        self.assertEqual((self.install_home / '.vimrc').read_text(), 'original vimrc')
        self.assertFalse((self.install_home / '.dotvim-backups').exists())

    @unittest.skipUnless(EDITOR and shutil.which('git'), 'Git and an editor are required')
    def test_pinned_install_upgrade_and_offline_repeat(self):
        upstream = self.scratch / "upstream with 'quote'"
        upstream.mkdir()

        def git(*arguments):
            return subprocess.check_output(
                ['git', '-c', 'user.name=Dotvim Test', '-c', 'user.email=test@example.invalid',
                 '-c', 'commit.gpgsign=false', '-c', 'core.hooksPath=/dev/null',
                 '-C', str(upstream), *arguments], env=self.environment,
                stderr=subprocess.STDOUT, text=True).strip()

        git('init', '--quiet')
        (upstream / 'plugin').mkdir()
        (upstream / 'plugin/trap.vim').write_text("throw 'Installer evaluated plugin code'\n")
        (upstream / 'ftdetect').mkdir()
        (upstream / 'ftdetect/trap.vim').write_text("throw 'Installer evaluated filetype detection'\n")
        git('add', '.')
        git('commit', '--quiet', '-m', 'Initial fixture')
        first = git('rev-parse', 'HEAD')
        (upstream / 'version').write_text('second revision\n')
        git('add', '.')
        git('commit', '--quiet', '-m', 'Update fixture')
        second = git('rev-parse', 'HEAD')
        manifest = self.checkout / 'plugins.vim'
        source = manifest.read_text()

        def pin(revision):
            manifest.write_text(re.sub(
                r"s:Plugin\('[^']+', '([^']+)', '[0-9a-f]{40}'",
                lambda match: "s:Plugin(" + vim_string(upstream.as_uri()) + ", '"
                + match[1] + "', '" + revision + "'", source))

        def check_revisions(revision):
            plugins = list((self.checkout / 'plugged').iterdir())
            self.assertEqual(len(plugins), 13)
            for plugin in plugins:
                actual = subprocess.check_output(['git', '-C', str(plugin), 'rev-parse', 'HEAD'],
                                                 text=True).strip()
                self.assertEqual(actual, revision, str(plugin))

        pin(first)
        self.install('--full')
        check_revisions(first)
        pin(second)
        self.install('--full')
        check_revisions(second)
        shutil.rmtree(upstream)
        self.install('--full')
        check_revisions(second)
        self.assertEqual((self.install_home / '.dotvim-profile').read_text(), 'full\n')

    def test_failed_profile_write_restores_configuration(self):
        (self.install_home / '.vimrc').write_text('original vimrc')
        (self.install_home / '.dotvim-profile').write_text('full\n')
        commands = self.scratch / 'bin'
        commands.mkdir()
        fake_cp = commands / 'cp'
        fake_cp.write_text('#!/bin/sh\nexit 1\n')
        fake_cp.chmod(0o755)
        self.install(success=False, environment={'PATH': str(commands) + os.pathsep + os.environ['PATH']})
        self.assertEqual((self.install_home / '.vimrc').read_text(), 'original vimrc')
        self.assertEqual((self.install_home / '.dotvim-profile').read_text(), 'full\n')
        self.assertFalse((self.install_home / '.vim').exists())

    def test_checkout_already_at_vim_directory(self):
        destination = self.install_home / '.vim'
        shutil.move(self.checkout, destination)
        self.checkout = destination
        self.install('--vim-only')
        self.assertFalse(destination.is_symlink())
        self.assertTrue((self.install_home / '.vimrc').samefile(destination / 'vimrc'))

    def test_nvim_only(self):
        self.install('--nvim-only')
        self.assertFalse((self.install_home / '.vimrc').exists())
        self.assertTrue((Path(self.environment['XDG_CONFIG_HOME']) / 'nvim' / 'init.vim').exists())


if __name__ == '__main__':
    unittest.main()

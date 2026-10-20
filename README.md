# dotvim

A shared Vim and Neovim configuration for macOS and Linux. Basic editing works
without plugins or external language runtimes. Optional tools add capabilities
independently, so a server can stay small while a workstation has more features.

## Install

```sh
git clone https://github.com/everbird/dotvim.git ~/.everbird-dotvim
sh ~/.everbird-dotvim/bootstrap.sh --basic
```

The default is `--basic`, for both editors. Use `--vim-only` or `--nvim-only` to
install just one entry point. Basic installation needs neither an editor nor Git
when using an existing local copy.

The installer links `~/.vim`, `~/.vimrc`, `~/.gvimrc`, and
`${XDG_CONFIG_HOME:-~/.config}/nvim` to this checkout or its entry files. Existing
files, directories, and broken symlinks are saved under `~/.dotvim-backups/` before
replacement. An existing Neovim configuration directory is backed up as a whole,
including `init.lua`. Repeating the same installation leaves correct links alone.

To use an existing checkout elsewhere:

```sh
sh /path/to/dotvim/bootstrap.sh --basic --checkout /path/to/dotvim
```

An absent `--checkout` directory is cloned first. Existing checkouts are used as
they are; the installer never pulls or resets them. A local copy of the project
can be installed in basic mode without Git. Git is needed to clone or fetch
plugins. Editor startup never downloads anything.

For a trial installation away from your real configuration:

```sh
DOTVIM_HOME=/tmp/dotvim-trial \
XDG_CONFIG_HOME=/tmp/dotvim-trial/.config \
sh ./bootstrap.sh --basic
```

## Compatibility and profiles

The shared configuration targets regular Vim 7.4+ builds with `+eval`,
`+autocmd`, and the standard runtime files, and Neovim 0.9+. Vim's tiny build and
plain vi lack the scripting features this configuration uses.
Language syntax follows the installed runtime; older runtimes have fewer filetypes.

| Profile | Behavior | Runtime dependencies |
| --- | --- | --- |
| `basic` | Native editing, file lookup, directory browsing, search, syntax, and completion | Vim or Neovim |
| `full` | Selected plugin packages, individually checked for required tools | Only the tools for features you use |

Both profiles work on both operating systems. macOS does not automatically imply
that Homebrew, Python, or other developer tools are present.

Switch profiles with the installer:

```sh
sh ~/.everbird-dotvim/bootstrap.sh --full
sh ~/.everbird-dotvim/bootstrap.sh --basic
```

The choice is stored in `~/.dotvim-profile`. Restart the editor after changing
profiles or installing plugins. To override the profile for one invocation:

```sh
DOTVIM_PROFILE=basic vim
DOTVIM_PROFILE=full nvim
```

Both editors use [vim-plug](https://github.com/junegunn/vim-plug) in the full
profile. It supports Vim versions without native packages and requires no Python,
Ruby, Lua, or Node.js runtime. Its unmodified `autoload/plug.vim` is included at
revision [`7e5aae5e1187842cb0b1d8def986e48d481c4410`](https://github.com/junegunn/vim-plug/tree/7e5aae5e1187842cb0b1d8def986e48d481c4410),
with its MIT license intact. Basic mode does not load the manager.

The shared plugin list and exact commit pins are in `plugins.vim`; downloads go
into the ignored `plugged/` directory. No Git submodules are needed. Individual
plugins and LSP features can still require a newer editor. The repeat plugin is
pinned to v1.2 to retain Vim 7 compatibility.

Even the full profile starts without downloaded plugins. Missing plugins or
tools are skipped, and native editing remains usable. Run `:DotvimHealth` to see
the selected profile, manager, enabled plugins, and reasons for skipped features.

## Optional features

`--full` fetches the 13 pinned plugin repositories. It does not install system
packages, run plugin build hooks, or download language servers.
Installation requires Git and either Vim or Neovim. Set `DOTVIM_INSTALL_EDITOR`
to select an executable explicitly. The installer checks every downloaded commit
before replacing configuration links. Repeating an installation with matching
pins works offline, and installed plugins that need no external tools can also
run without Git.

| Feature | Packages | Required tools or capabilities |
| --- | --- | --- |
| Surround editing and repeat | surround, repeat | None |
| Commenting and alignment | nerdcommenter, easyalign | None |
| File tree | nerdtree | None |
| One Dark theme | onedark | None; basic mode uses desert |
| Git commands | fugitive | `git` |
| Undo history browser | undotree | Persistent undo support and `diff` |
| Symbol outline | tagbar | Universal Ctags |
| Fuzzy file search | fzf, fzf-vim | Vim 8+ or Neovim, and `fzf` 0.63+ |
| Vim LSP client | lsp | Opt-in; Vim 9+ with jobs and channels, and language servers |
| Personal snippets | ultisnips | Opt-in; Vim 8.2+ with Python 3 support, or Neovim's Python provider |

`rg` improves `:Grep` in either profile. Without it, search uses Vim's built-in
`:vimgrep` and quickfix. Without fzf, `<C-p>` starts native `:find` completion.
Without NERDTree, the directory mappings use the runtime's native file browser.

On a workstation, install whichever optional tools you want. For example:

```sh
# macOS with Homebrew
brew install ripgrep fzf universal-ctags

# Debian/Ubuntu (package versions vary)
sudo apt-get install ripgrep fzf universal-ctags
```

An older fzf executable is skipped. The minimum above follows the pinned
fzf-vim implementation; its upstream README may advertise an older minimum.
Preview helpers such as bat, Perl-based tag commands, and other fzf commands
can have additional optional dependencies; see the
[fzf-vim documentation](https://github.com/junegunn/fzf.vim).

Tagbar checks the implementation behind `ctags`, `ctags-universal`, and `uctags`.
BSD/macOS ctags and Emacs ctags are skipped. Executables are found through PATH,
so Intel Homebrew, Apple Silicon Homebrew, and Linux need no hardcoded paths.

## Local settings

Both editors read `~/.vimrc.local` before configuring optional features. This file
is yours and is never written by the installer. For example:

```vim
let g:dotvim_profile = 'full'
let g:dotvim_lsp = 1
let g:dotvim_snippets = 0
let g:dotvim_colorscheme = 'onedark'

" Optional executable overrides, including paths with spaces.
" let g:dotvim_ctags = '/custom/path/to/ctags'
" let g:dotvim_python = '/custom/virtualenv/bin/python3'

" Optional final option and mapping overrides.
function! DotvimLocal() abort
    set nocursorcolumn
endfunction
```

`DOTVIM_PROFILE` takes precedence over the file. Other settings include
`g:dotvim_truecolor`, `g:dotvim_guifont`, `g:dotvim_guifontwide`, and
`g:dotvim_state_dir`. True color is enabled when the terminal advertises it via
`COLORTERM` or a direct-color `TERM`; the local setting can override detection.
The GUI font defaults to Menlo only in MacVim.

Swap, backup, and persistent undo directories are kept under
`${XDG_STATE_HOME:-~/.local/state}/dotvim`. An unavailable state directory does
not prevent editing. Viminfo/Shada keep the original preference to omit registers.

## LSP and snippets

LSP is off by default. Set `g:dotvim_lsp = 1` in the full profile to enable it:

- Neovim 0.11+ uses its built-in `vim.lsp.config` and `vim.lsp.enable` APIs.
- Vim 9+ uses [yegappan/lsp](https://github.com/yegappan/lsp).
- Earlier editors keep their native completion and editing features.

Available servers are detected on PATH: `pylsp`, `gopls`, `clangd`,
`rust-analyzer`, and `typescript-language-server`. Only opening a corresponding
file starts its server. Install the servers you actually use separately; their
own dependencies apply only to those language features. No Node.js or embedded
Python requirement is imposed by the shared LSP configuration.

To replace that list, define `g:dotvim_lsp_servers` in `~/.vimrc.local`:

```vim
let g:dotvim_lsp_servers = [
    \ {'name': 'gopls', 'cmd': ['gopls'], 'filetypes': ['go', 'gomod'],
    \  'root_markers': ['go.work', 'go.mod', '.git']}
    \ ]
```

The original mindflow snippets are preserved as
`snippets/markdown_mindflow.snippets` so modern Markdown filetypes can find them.
Set `g:dotvim_snippets = 1` to load UltiSnips when the Python integration is
available. Vim needs `+python3`; Neovim needs its Python provider and `pynvim`.
Use `mfs` and `mfss` in Markdown, then Tab to expand. These snippets retain their
original Python timestamp interpolation. Snippet dependencies are independent
of LSP and are never required for basic editing.

## Familiar mappings

The leader remains comma.

| Mapping | Action |
| --- | --- |
| `,ve` / `,vs` | Edit / reload the shared vimrc |
| `,cd` | Change to the current file's directory |
| `,d` | Insert today's date |
| `,hl` / `,l` / `,w` / `,s` | Toggle search highlighting / hidden characters / wrapping / spelling |
| `,py` | Save and run the current file with Python 3, falling back to Python |
| `Ctrl-n` / `Ctrl-b` | Next / previous buffer |
| `Ctrl-p` | fzf files, or native file lookup |
| `,nt` / `,nf` | Browse the working directory / current file's directory |
| `wm` / `,wm` | Open/toggle the file browser (sidebar toggle when supported) |
| `Ctrl-Up` / `Ctrl-Down` | Move a line or selected lines |
| `F3` / `:Grep {pattern}` | Search into quickfix |
| `F4` | Toggle Tagbar when available |
| `F5` | Strip trailing whitespace and collapse duplicate blank lines |
| `F6` | Toggle Undotree when available |
| `,a` / visual Enter | EasyAlign in the full profile |
| `,cc` / `,c<Space>` | NERDCommenter comment / toggle in the full profile |
| `,gd` / `,gh` / `,gr` | LSP definition / hover / references |
| `F8` / `Ctrl-j` / `Ctrl-k` | UltiSnips list / next / previous placeholder |

## Updates, migration, and recovery

Update the configuration explicitly, then refresh the selected profile:

```sh
git -C ~/.everbird-dotvim pull --ff-only
sh ~/.everbird-dotvim/bootstrap.sh --full
```

Use `--basic` instead on a minimal machine. Full mode restores the revisions
recorded in `plugins.vim`. Existing checkouts at those revisions are reused;
changed pins are updated and missing plugins are installed. vim-plug generates
plugin help tags during installation.

Inside a full-profile editor, `:PlugStatus` reports plugin state, `:PlugInstall`
installs missing plugins, and `:PlugUpdate` updates them to the declared pins.
`PlugUpdate` does not advance pinned plugins to upstream HEAD. `:PlugClean`
offers to remove repositories no longer declared. Plugins disabled by capability
checks or opt-in settings remain declared, so cleanup retains them.

To update a plugin intentionally, change its commit in `plugins.vim`, run
`bootstrap.sh --full`, and test the relevant editor versions. Updating vim-plug
itself is a separate, reviewed replacement of `autoload/plug.vim`; record its
upstream revision here. Routine configuration updates do not require `:PlugUpgrade`.

The former Pathogen `bundle/` tree and the earlier `pack/dotvim/opt/` layout are
no longer used by this configuration. Old directories left by
a Git upgrade can be archived after checking for local plugin changes. Redundant
buffer browsers, Python-mode/Syntastic, Ruby-based explorers, Gundo, and bundled
language syntax plugins have been consolidated into native features, the optional
LSP client, and the smaller package set. The original themes remain in `colors/`.

Each installation prints its backup directory. Only replaced entries are saved:

| Saved entry | Original location |
| --- | --- |
| `vim` | `~/.vim` |
| `vimrc` | `~/.vimrc` |
| `gvimrc` | `~/.gvimrc` |
| `nvim` | `${XDG_CONFIG_HOME:-~/.config}/nvim` |
| `profile` | `~/.dotvim-profile` |

To restore one, move the installed link aside and move the corresponding saved
entry back to its original location. Download failures leave existing editor
configuration alone; failures while linking restore entries already moved.

## Maintenance checks

Tests use Python 3's standard library and write only to temporary directories.
Python is a development test dependency, not an editor runtime dependency.

```sh
sh -n bootstrap.sh
shellcheck -s sh bootstrap.sh
python3 -m unittest discover -s tests -v
DOTVIM_TEST_EDITOR=nvim python3 -m unittest discover -s tests -v
```

Run `vim -u NONE -i NONE -n -es --noplugin -S scripts/install_plugins.vim` first
to include plugin integration tests; `nvim` can run the same command. This downloads
plugins without changing editor configuration links. The GitHub Actions matrix
covers current Vim and Neovim on Linux/macOS, Vim 7.4 without native packages,
and Neovim 0.9/0.11. Checks include missing plugins and tools, startup without
downloads, reloading, path quoting, LSP initialization, pinned upgrades, offline
reinstallation, backups, idempotence, and rollback. The installer tests use local
Git fixtures and do not need network access.

Keep comments, documentation, commit messages, and PR descriptions in English.

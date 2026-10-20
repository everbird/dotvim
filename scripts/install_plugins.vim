" Install pinned plugins without evaluating the user's configuration or plugin code.
set nocompatible nomore
set shell=/bin/sh
let g:dotvim_root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let &runtimepath = escape(g:dotvim_root, ',') . ',' . escape($VIMRUNTIME, ',')
let g:dotvim_profile = 'full'
let g:dotvim_installing = 1

function! s:Revision(spec) abort
    let revision = system('git -C ' . shellescape(a:spec.dir) . ' rev-parse --verify HEAD 2>/dev/null')
    return v:shell_error ? '' : matchstr(revision, '^\x\{40}')
endfunction

try
    execute 'source ' . fnameescape(g:dotvim_root . '/plugins.vim')
    if !exists(':PlugUpdate') || empty(get(g:, 'plugs', {}))
        throw 'vim-plug and Git are required to install plugins'
    endif
    let s:pending = []
    for s:name in g:plugs_order
        if s:Revision(g:plugs[s:name]) !=# g:plugs[s:name].commit
            call add(s:pending, s:name)
        endif
    endfor
    if !empty(s:pending)
        execute 'PlugUpdate --sync ' . join(s:pending)
    endif
    for s:name in g:plugs_order
        if s:Revision(g:plugs[s:name]) !=# g:plugs[s:name].commit
            throw 'Plugin installation failed: ' . s:name . ' (expected ' . g:plugs[s:name].commit . ')'
        endif
    endfor
catch
    call writefile([v:exception, v:throwpoint], '/dev/stderr')
    cquit
endtry
if !has('nvim') && v:version < 800
    " Vim 7.4 counts vim-plug's silent! unmaps as Ex errors. Pins are verified;
    " leave Ex mode so a successful installation returns zero.
    visual
endif
qa!

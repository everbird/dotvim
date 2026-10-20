" Small helpers shared by Vim and Neovim; no plugin dependencies.
function! dotvim#browse(file_directory) abort
    let directory = a:file_directory && !empty(expand('%:p')) ? expand('%:p:h') : getcwd()
    if exists(':NERDTreeToggle') == 2
        execute (a:file_directory ? 'NERDTree ' : 'NERDTreeToggle ') . fnameescape(directory)
    elseif exists(':Lexplore') == 2
        if !a:file_directory && exists('t:netrw_lexbufnr') && bufwinnr(t:netrw_lexbufnr) > 0
            Lexplore
        else
            execute 'Lexplore ' . fnameescape(directory)
        endif
    else
        execute 'edit ' . fnameescape(directory)
    endif
endfunction

function! dotvim#optional(command, feature) abort
    if exists(':' . a:command) == 2
        execute a:command
    else
        echo a:feature . ' is optional. See :DotvimHealth and README.md.'
    endif
endfunction

function! dotvim#python() abort
    let interpreter = get(g:, 'dotvim_python', executable('python3') ? 'python3' : 'python')
    if !executable(interpreter) || empty(expand('%:p'))
        echo 'Save this buffer and install Python to run it.'
        return
    endif
    update
    execute '!' . escape(shellescape(interpreter) . ' ' . shellescape(expand('%:p')), '!%#')
endfunction

function! dotvim#grep(pattern) abort
    if executable('rg')
        let output = system('rg --vimgrep --smart-case -- ' . shellescape(a:pattern) . ' .')
        if v:shell_error > 1
            echohl WarningMsg
            echomsg output
            echohl None
            return
        endif
        let saved_format = &errorformat
        try
            let &errorformat = '%f:%l:%c:%m'
            cgetexpr output
        finally
            let &errorformat = saved_format
        endtry
    else
        try
            execute 'vimgrep /' . escape(a:pattern, '/') . '/gj **/*'
        catch /^Vim\%((\a\+)\)\=:E480/
            call setqflist([])
        endtry
    endif
    if !empty(getqflist())
        copen
    else
        echo 'No matches.'
    endif
endfunction

function! dotvim#clean() abort
    let saved_search = @/
    let saved_view = winsaveview()
    let changed = b:changedtick
    try
        silent keepjumps %s/\s\+$//e
        if b:changedtick != changed
            undojoin
        endif
        silent keepjumps %s/\n\{3,}/\r\r/ge
    finally
        let @/ = saved_search
        call winrestview(saved_view)
    endtry
endfunction

function! dotvim#health() abort
    echo (has('nvim') ? 'Neovim' : 'Vim') . ' / profile: ' . g:dotvim_profile
    echo 'Plugin loader: ' . get(g:, 'dotvim_package_loader', 'disabled')
    echo 'Enabled plugins: ' . join(get(g:, 'dotvim_loaded_plugins', []), ', ')
    for reason in get(g:, 'dotvim_skipped_plugins', [])
        echo 'Skipped: ' . reason
    endfor
    echo 'LSP: ' . get(g:, 'dotvim_lsp_status', 'disabled (opt in with g:dotvim_lsp)')
    for tool in ['git', 'rg', 'fzf', 'ctags', 'python3']
        echo tool . ': ' . (executable(tool) ? 'available' : 'optional, not found')
    endfor
endfunction

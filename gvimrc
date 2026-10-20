" GUI settings are isolated from terminal Vim and Neovim.
if !has('gui_running')
    finish
endif
set guioptions-=T
if has('gui_macvim')
    let &guifont = get(g:, 'dotvim_guifont', 'Menlo:h14')
    let &guifontwide = get(g:, 'dotvim_guifontwide', &guifont)
    command! FS set guifont=Menlo:h17
elseif exists('g:dotvim_guifont')
    let &guifont = g:dotvim_guifont
endif

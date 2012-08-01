call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

filetype plugin indent on

"set mouse=a

set encoding=utf-8
set nu
set listchars=tab:>-,trail:~
set shiftwidth=4
set tabstop=4
set expandtab
set smarttab
set list

" Shortcut to rapidly toggle `set list`
nmap <leader>l :set list!<CR>

set guifont=Monaco:h12
set guifontwide=Monaco:h12

set autoindent
set cc=72,79
set ruler
set undofile

set nocompatible
syntax on
set hlsearch
set hidden

"colorscheme desert
"colorscheme blackboard
set t_Co=256
colorscheme wombat256mod

set go-=T
set bg=dark
if &background == "dark"
    hi normal guibg=black
endif

set incsearch

let Tlist_Ctags_Cmd="/usr/local/bin/ctags"
let Tlist_Show_One_File=1
let Tlist_Exit_OnlyWindow=1

"-----------------------------------------------------------------------------
" NERD_tree.vim与winmanager.vim 的集成设置
"-----------------------------------------------------------------------------
let g:winManagerWindowLayout='NERDTree|TagList,BufExplorer'

"let g:winManagerWindowLayout='FileExplorer|TagList'
nmap wm :WMToggle<cr>

":set cscopequickfix=s-,c-,d-,i-,t-,e-

let g:miniBufExplMapWindowNavArrows = 1
let g:miniBufExplMapCTabSwitchBufs = 1

nnoremap <silent> <F3> :Grep<CR>

" settings for tagbar
nnoremap <silent> <F4> :TagbarToggle<CR>
let g:tagbar_ctags_bin = '/usr/local/bin/ctags'
let g:tagbar_width = 30

" settings for gundo
nnoremap <silent> <F6> :GundoToggle<CR>

" Bubbing single line
"nmap <C-Up> ddkP
"nmap <C-Down> ddp
nmap <C-Up> [e
nmap <C-Down> ]e

" Bubbing multiple lines
"vmap <C-UP> xkP`[V`]
"vmap <C-Down> xp`[V`]
vmap <C-UP> [egv
vmap <C-Down> ]egv

" Show hightlighting groups for current word
nmap <C-S-P> :call <SID>SynStack()<CR>
function! <SID>SynStack()
    if !exists("*synstack")
        return
    endif
    echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

if has("autocmd")
    autocmd bufwritepost .vimrc source $MYVIMRC
endif

nmap <leader>v :tabe $MYVIMRC<CR>

" Toggle spell checking on and off with `\s`
nmap <silent><leader>s :set spell!<CR>

function! <SID>StripTrailingWhitespacesAndDuplicateBlankLines()
    " Preparation: save last search, and cursor position.
    let _s=@/
    let l = line(".")
    let c = col(".")
    " Do the business:
    %s/\s\+$//e
    %s/^\n$//g
    " Clean up: restore previous search history, and cursor position
    let @/=_s
    call cursor(l, c)
endfunction

nnoremap <silent> <F5> :call <SID>StripTrailingWhitespacesAndDuplicateBlankLines()<CR>

" In line copy and paste to system clipboard
" reference: http://vim.wikia.com/wiki/In_line_copy_and_paste_to_system_clipboard
vmap <C-c> y:call system("pbcopy", getreg("\""))<CR>
nmap <C-v> :call setreg("\"",system("pbpaste"))<CR>p

if has("autocmd")
    filetype plugin indent on
endif

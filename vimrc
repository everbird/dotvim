" Shared configuration for Vim 7.4+ and Neovim.
set nocompatible

let g:dotvim_root = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let s:root = escape(g:dotvim_root, ',')
if stridx(',' . &runtimepath . ',', ',' . s:root . ',') < 0
    let &runtimepath = s:root . ',' . &runtimepath
endif

" Machine-specific settings are shared by both editors and never tracked.
let s:local = get(g:, 'dotvim_local_config', expand('~/.vimrc.local'))
if filereadable(s:local)
    execute 'source ' . fnameescape(s:local)
endif
if !exists('g:dotvim_profile')
    let s:profile = expand('~/.dotvim-profile')
    let g:dotvim_profile = filereadable(s:profile) ? get(readfile(s:profile, '', 1), 0, 'basic') : 'basic'
endif
if !empty($DOTVIM_PROFILE)
    let g:dotvim_profile = $DOTVIM_PROFILE
endif
if index(['basic', 'full'], g:dotvim_profile) < 0
    let g:dotvim_profile = 'basic'
endif

set backspace=indent,eol,start
set encoding=utf-8
set hidden
set hlsearch incsearch ignorecase smartcase
set cursorline cursorcolumn
set laststatus=2 ruler number
set nostartofline nofoldenable
set shortmess+=I
set showmatch visualbell
set virtualedit=all
set tabstop=4 softtabstop=4 shiftwidth=4 expandtab autoindent smarttab
set wrap linebreak
set list listchars=tab:>-,trail:~
set wildmenu
set wildignore+=*.o,*.so,*.pyc,*.swp,*.zip,*~,.DS_Store,*/.git/*,*/node_modules/*
set path+=**
set completeopt=menu,menuone
set background=dark
if exists('+colorcolumn')
    set colorcolumn=72,79
endif
if exists('+relativenumber')
    set relativenumber
endif
if exists('+spelllang')
    set spelllang=en_gb
endif
if exists('+pastetoggle')
    set pastetoggle=<F2>
endif
if has('nvim') && exists('+shada')
    set shada-=<50 shada+=<0
elseif exists('+viminfo')
    set viminfo-=<50 viminfo+=<0
endif
if has('nvim') || v:version >= 800
    set completeopt+=noinsert
endif
if exists('+termguicolors') && get(g:, 'dotvim_truecolor', $COLORTERM =~# 'truecolor\|24bit' || $TERM =~# 'direct')
    set termguicolors
endif

" Keep state out of edited projects; unwritable state directories are optional.
let s:state = get(g:, 'dotvim_state_dir', (empty($XDG_STATE_HOME) ? expand('~/.local/state') : $XDG_STATE_HOME) . '/dotvim')
for s:kind in ['swap', 'backup', 'undo']
    let s:directory = s:state . '/' . s:kind
    let s:parent = s:directory
    while !isdirectory(s:parent) && empty(getftype(s:parent))
        let s:parent = fnamemodify(s:parent, ':h')
    endwhile
    if !isdirectory(s:parent) || filewritable(s:parent) != 2
        continue
    endif
    try
        if !isdirectory(s:directory)
            call mkdir(s:directory, 'p', 0700)
        endif
        if filewritable(s:directory) == 2
            let s:directory = escape(s:directory, ',') . '//'
            if s:kind ==# 'swap'
                let &directory = s:directory
            elseif s:kind ==# 'backup'
                let &backupdir = s:directory
            elseif has('persistent_undo')
                let &undodir = s:directory
                set undofile
            endif
        endif
    catch
        " Editing still works when the state directory cannot be created.
    endtry
endfor

let mapleader = ','
nnoremap <silent> <Leader>ve :execute 'edit ' . fnameescape(g:dotvim_root . '/vimrc')<CR>
nnoremap <silent> <Leader>vs :execute 'source ' . fnameescape(g:dotvim_root . '/vimrc')<CR>
nnoremap <Leader>cd :execute 'cd ' . fnameescape(expand('%:p:h'))<CR>:pwd<CR>
nnoremap <Leader>d "=strftime('%d %b %Y')<CR>P
nnoremap <silent> <C-n> :bnext<CR>
nnoremap <silent> <C-b> :bprevious<CR>
nnoremap <Leader>hl :set invhlsearch<CR>:set hlsearch?<CR>
nnoremap <silent> <Leader>l :set invlist<CR>
nnoremap <Leader>w :set invwrap<CR>
if exists('+spell')
    nnoremap <Leader>s :set invspell<CR>
endif
nnoremap <silent> <Leader>py :call dotvim#python()<CR>
inoremap <C-]> {<CR>}<Esc>O
nnoremap <Leader>q di'hPl2x<CR>
nnoremap <silent> <C-Up> :<C-u>silent! move .-2<CR>==
nnoremap <silent> <C-Down> :<C-u>silent! move .+1<CR>==
xnoremap <silent> <C-Up> :move '<-2<CR>gv=gv
xnoremap <silent> <C-Down> :move '>+1<CR>gv=gv

" Native fallbacks remain available without any installed plugins.
nnoremap <C-p> :find<Space>
nnoremap <silent> <Leader>nt :call dotvim#browse(0)<CR>
nnoremap <silent> <Leader>nf :call dotvim#browse(1)<CR>
nnoremap <silent> <Leader>wm :call dotvim#browse(0)<CR>
nnoremap <silent> wm :call dotvim#browse(0)<CR>
nnoremap <F3> :Grep<Space>
nnoremap <silent> <F4> :call dotvim#optional('TagbarToggle', 'Tagbar with Universal Ctags')<CR>
nnoremap <silent> <F5> :call dotvim#clean()<CR>
nnoremap <silent> <F6> :call dotvim#optional('UndotreeToggle', 'Undotree')<CR>
command! -nargs=+ Grep call dotvim#grep(<q-args>)
command! DotvimHealth call dotvim#health()

if filereadable(g:dotvim_root . '/plugins.vim')
    execute 'source ' . fnameescape(g:dotvim_root . '/plugins.vim')
endif
filetype plugin indent on

if has('autocmd')
    augroup dotvim
        autocmd!
        autocmd BufRead,BufNewFile *.ini,supervisord.conf setfiletype dosini
        autocmd BufRead,BufNewFile Vagrantfile,Rakefile setfiletype ruby
        autocmd BufRead,BufNewFile */webserver/files/conf/* setfiletype nginx
        " Preserve the original two-space indentation for these languages.
        autocmd FileType python,ruby,html,css,javascript,javascriptreact,typescript,typescriptreact,jade,pug,scss,yaml setlocal shiftwidth=2 tabstop=2 softtabstop=2
    augroup END
    if !empty(&filetype) && exists('#dotvim#FileType#' . &filetype)
        execute 'doautocmd dotvim FileType ' . &filetype
    endif
endif

if has('syntax')
    syntax enable
    let s:theme = get(g:, 'dotvim_colorscheme', index(get(g:, 'dotvim_loaded_plugins', []), 'onedark') >= 0 ? 'onedark' : 'desert')
    let s:theme_available = 0
    for s:extension in (has('nvim') ? ['vim', 'lua'] : ['vim'])
        let s:color = 'colors/' . s:theme . '.' . s:extension
        if !empty(globpath(&runtimepath, s:color))
            let s:theme_available = 1
            break
        endif
        if exists('+packpath') && (!empty(globpath(&packpath, 'pack/*/opt/*/' . s:color)) || !empty(globpath(&packpath, 'pack/*/start/*/' . s:color)))
            let s:theme_available = 1
            break
        endif
    endfor
    execute 'colorscheme ' . fnameescape(s:theme_available ? s:theme : 'desert')
endif

" Optional final overrides, defined in ~/.vimrc.local.
if exists('*DotvimLocal')
    call DotvimLocal()
endif

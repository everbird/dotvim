" List of mappings
"----------------
" ,ve   - Open vimrc
" ,vs   - Source vimrc
" ,d    - Insert current date
" ,hl   - Toggle search highlighting
" ,l    - Show hidden characters
" ,py   - Execute current python script
" ,w    - Toggle word wrapping
" ,s    - Toggle spell checking
"
" ,nt   - Open NERDtree
" ,nf   - Open NERDtree using current file's directory
" ,wm   - Toggle NERDTree
"
" C-down    - Move current line/selection down
" C-up      - Move current line/selection up
" C-]       - Simple brace completion

" Pathogen
call pathogen#infect()

"==============================================================================
"HOW IT WORKS
"==============================================================================
set backspace=indent,eol,start  "Allows backspacing over stuff
set complete+=t                 "Tag completion
"set cpoptions+=$                "Overwrite text (visually)
set cursorline
set cursorcolumn
set encoding=utf-8
set fillchars=                  "Remove the characters in window separators
set hidden                      "Allows hidden buffers with changes
set hlsearch                    "When there is a previous search pattern, highlight all its matches.
set ignorecase                  "Search is case insensitive unless...
set incsearch                   "Show match while entering search
set laststatus=2                "Status line is always on
"set mouse-=a                    "Disable mouse
set nocompatible                "Git tae, Vi compatibility
set nostartofline               "Stop jumping to the start of a line
set nofoldenable                "Don't fold by default"
set pastetoggle=<F2>            "Use F2 to toggle paste on/off in insert mode
set ruler                       "Show the line and column number of the cursor position, separated by a comma.
"set scrolloff=8                 "Keeps the cursor centered while scrolling
"set shellslash                  "Use / instead of \ for file paths and such
set shortmess+=I                "Remove the intro message
set showmatch                   "Jump to matching paren when inserting
set smartcase                   "An uppercase letter is found
set spl=en_gb                   "Language for spellchecking
set vb                          "Visual bell
set viminfo+=<0                 "Don't save registers
set viminfo-=<50                "Same as above, removes default stuff from viminfo
set virtualedit=all             "Cursor can move anywhere (ish)
"set wildmenu                    "Display options when autocompleting in cmdline mode

set fileencoding=utf8
set termencoding=utf8

if version >= 703
    set colorcolumn=72,79           "Highlight columns
    set relativenumber              "Show the line number relative to the line with the cursor in front of each line.
    set undofile
endif

"filetype off
filetype plugin indent on       "Filetype plugin
syntax on                       "Syntax highlighting

"Autocmds
"--------
if has('autocmd')
    "Setting filetypes
    au BufRead,BufNewFile *.ini  set filetype=dosini
    au BufRead,BufNewFile supervisord.conf   set filetype=dosini
    au BufRead,BufNewFile Vagrantfile   set filetype=ruby
    au BufRead,BufNewFile Rakefile   set filetype=ruby

    " nginx
    au BufRead,BufNewFile */webserver/files/conf/* set ft=nginx

    "html/css/js indentation
    au BufRead,BufNewFile *.html   setl shiftwidth=2 tabstop=2 softtabstop=2
    au BufRead,BufNewFile *.css    setl shiftwidth=2 tabstop=2 softtabstop=2
    au BufRead,BufNewFile *.js     setl shiftwidth=2 tabstop=2 softtabstop=2
    au BufRead,BufNewFile *.jade   setl shiftwidth=2 tabstop=2 softtabstop=2
    au BufRead,BufNewFile *.scss   setl shiftwidth=2 tabstop=2 softtabstop=2
    au BufRead,BufNewFile *.yml    setl shiftwidth=2 tabstop=2 softtabstop=2

    au BufRead,BufNewFile Vagrantfile   setl shiftwidth=2 tabstop=2 softtabstop=2
    au BufRead,BufNewFile Rakefile   setl shiftwidth=2 tabstop=2 softtabstop=2
    au BufRead,BufNewFile *.rb  setl shiftwidth=2 tabstop=2 softtabstop=2

endif

"==============================================================================
"MAPPINGS
"==============================================================================
let mapleader=','

"Default vimrc mappings
nnoremap    <Leader>ve :e $MYVIMRC<CR>
nnoremap    <Leader>vs :so $MYVIMRC<CR>

"Macvim vimrc mappings
if has('unix')
    nnoremap    <Leader>ve :e ~/.gvimrc<CR>
    nnoremap    <Leader>vs :so ~/.gvimrc<CR>
endif

"Cd to current file's dir
nnoremap    <Leader>cd  :cd %:h<CR>:pwd<CR>

"Insert current date
nnoremap    <Leader>d  "=strftime('%d %b %Y')<CR>P

"Moving between buffers
nnoremap    <silent> <C-n> :bn<CR>
nnoremap    <silent> <C-b> :bp<CR>

"Toggle search highlighting
nnoremap    <Leader>hl :set invhls<CR>:set hls?<CR>

"Show hidden chars
nnoremap    <silent> <Leader>l :set invlist<CR>

"Run python script
nnoremap    <Leader>py :!python %<CR>

"wrap / Nowrap
nnoremap    <Leader>w :set invwrap<CR>

"Spell checking
nnoremap    <Leader>s :set invspell<CR>

"Simple brace completion
inoremap    <C-]>   {<CR>}<ESC>O

"Remove quoutes
nnoremap    <Leader>q di'hPl2x<CR>

"==============================================================================
"HOW IT LOOKS
"==============================================================================

set t_Co=256
colorscheme wombat256mod

set tabstop=4           "Tab character width
set softtabstop=4       "Amount of whitespace to be inserted
set shiftwidth=4        "Amount of whitespace in Normal mode
set expandtab           "Spaces rather than tabs
set autoindent
set smarttab

set number              "Line numbering
set background=dark     "Better colours for a dark background

set go-=T

"Stops words being hypenated when wrapping
set wrap lbr

" Show hidden tabs
set list!

" Shortcut to rapidly toggle `set list`
nmap <leader>l :set list!<CR>

"Setting hidden chars
set listchars=tab:>-,trail:~
"set listchars=tab:>-,trail:~,eol:¬
"" Use the same symbols as TextMate for tabstops and EOLs
"set listchars=tab:▸\ ,eol:¬


"==============================================================================
"PLUGINS
"==============================================================================

"NERDTree
let NERDTreeWinPos='left'
nnoremap <silent> <Leader>nt :NERDTree.<CR>
"Open tree using file's directory
nnoremap <silent> <Leader>nf :NERDTree %:p:h<CR>
nmap wm :NERDTreeToggle<cr>

" MiniBufExpl
let g:miniBufExplMapWindowNavArrows = 1
let g:miniBufExplMapCTabSwitchBufs = 1

" Grep
nnoremap <silent> <F3> :Grep<CR>

" Tagbar
nnoremap <silent> <F4> :TagbarToggle<CR>
if executable("/usr/local/bin/ctags")
    let g:tagbar_ctags_bin = '/usr/local/bin/ctags'
else
    let g:tagbar_ctags_bin = '/usr/bin/ctags'
endif
let g:tagbar_width = 30
" For gotags per https://github.com/jstemmer/gotags
let g:tagbar_type_go = {
	\ 'ctagstype' : 'go',
	\ 'kinds'     : [
		\ 'p:package',
		\ 'i:imports:1',
		\ 'c:constants',
		\ 'v:variables',
		\ 't:types',
		\ 'n:interfaces',
		\ 'w:fields',
		\ 'e:embedded',
		\ 'm:methods',
		\ 'r:constructor',
		\ 'f:functions'
	\ ],
	\ 'sro' : '.',
	\ 'kind2scope' : {
		\ 't' : 'ctype',
		\ 'n' : 'ntype'
	\ },
	\ 'scope2kind' : {
		\ 'ctype' : 't',
		\ 'ntype' : 'n'
	\ },
	\ 'ctagsbin'  : 'gotags',
	\ 'ctagsargs' : '-sort -silent'
\ }

" Gundo
nnoremap <silent> <F6> :GundoToggle<CR>

" Python-mode
let g:pymode_virtualenv = 1 "Enable automatic virtualenv detection
let g:pymode_python = 'python3'


" CtrlP
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'rc'
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*~,.DS_Store  " MacOSX/Linux
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\.git$\|\.hg$\|\.svn$',
  \ 'file': '\.exe$\|\.so$\|\.dll$',
  \ 'python': '\.pyc$\|\.ptlc$',
  \ 'link': 'some_bad_symbolic_links',
  \ }

" unimpaired
" Bubbing single line
nmap <C-Up> [e
nmap <C-Down> ]e

" Bubbing multiple lines
vmap <C-UP> [egv
vmap <C-Down> ]egv

" LustyExplorer
let g:LustyJugglerSuppressRubyWarning = 1
let g:LustyExplorerSuppressRubyWarning = 1


"==============================================================================
"FUNCTIONS
"==============================================================================

if has("autocmd")
    autocmd bufwritepost .vimrc source $MYVIMRC

    " Resovle the stange color mass up issue
    if !has('gui_macvim')
        au VimEnter * source ~/.vim/bundle/wombat256mod/colors/wombat256mod.vim
    endif
endif

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
"vmap <C-S-c> y:call system("pbcopy", getreg("\""))<CR>
"nmap <C-S-v> :call setreg("\"",system("pbpaste"))<CR>p

hi link EasyMotionTarget ErrorMsg
hi link EasyMotionShade  Comment

" ultisnips
let g:UltiSnipsListSnippets = "<F8>"
let g:UltiSnipsJumpForwardTrigger="<C-j>"
let g:UltiSnipsJumpBackwardTrigger="<C-k>"
let g:UltiSnipsDontReverseSearchPath="1"
let g:UltiSnipsSnippetDirectories = ['UltiSnips', 'snippets']

" vim-markdonw
let g:vim_markdown_initial_foldlevel=1

" vim-easy-align
" Start interactive EasyAlign in visual mode (e.g. vip<Enter>)
vmap <Enter> <Plug>(EasyAlign)
"
" Start interactive EasyAlign for a motion/text object (e.g. <Leader>aip)
nmap <Leader>a <Plug>(EasyAlign)

" Disable new window auto documentation 
" reference: https://github.com/klen/python-mode/issues/384
set completeopt=menu

" vim freezes when using pymode autocomplete, disable it
" reference: https://github.com/klen/python-mode/issues/405
let g:pymode_rope_lookup_project = 0
let g:pymode_rope_complete_on_dot = 0
let g:pymode_rope = 0

call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

filetype plugin indent on
set mouse=a

set encoding=utf-8
set nu
set listchars=tab:>-,trail:~
set shiftwidth=4
set tabstop=4
set expandtab
set smarttab
set list

set guifont=Monaco:h12
set guifontwide=Monaco:h12

set lines=42 columns=160
set autoindent

set cc=72,79
set ruler

set undofile

syntax on
set hlsearch
set hidden

colorscheme desert

set go-=T
set bg=dark
if &background == "dark"
    hi normal guibg=black
    set transp=8
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

:set cscopequickfix=s-,c-,d-,i-,t-,e-

"set :filetype plugin on
"source cscope_maps.vim

let g:miniBufExplMapWindowNavArrows = 1
let g:miniBufExplMapCTabSwitchBufs = 1

nnoremap <silent> <F3> :Grep<CR>

"-----------------------------------------------------------------------------
" lookupfile.vim 插件设置
"-----------------------------------------------------------------------------

"let g:LookupFile_MinPatLength = 2               "最少输入2个字符才开始查找
"let g:LookupFile_PreserveLastPattern = 0        "不保存上次查找的字符串
"let g:LookupFile_PreservePatternHistory = 1     "保存查找历史
"let g:LookupFile_AlwaysAcceptFirst = 1          "回车打开第一个匹配项目
"let g:LookupFile_AllowNewFiles = 0              "不允许创建不存在的文件
"let g:LookupFile_SortMethod = ""                "关闭对搜索结果的字母排序
"
""设置tag文件的名字
"if filereadable("/Users/everbird/shadow/reading/filenametags")
"let g:LookupFile_TagExpr ='"/Users/everbird/shadow/reading/filenametags"'
"endif


""-------------------------------------------------------------------------- --------------------------
""  Make *.html  (and friends) to refresh firefox using  MozRepl. on save
""-------------------------------------------------------------------------- --------------------------
""autocmd BufWriteCmd  *.html,*.css,*.gtpl  : call Refresh_firefox()
""-------------------------------------------------------------------------- --------------------------
""
"" When editing an .html, .css, or .gtpl template file, make Firefox
"" refresh once the buffer is saved, preserving the current scroll offset.
""
"" Requires:
""       [2]  MozRepl must be installed & running in Firefox
""
""       [1]  Netcat (nc) must be on your path.
""
""       [3]  Firefox & vim are both on the same machine (localhost).
""            Actually, you can fix that if you want by adjusting
""            this script + your MosRepl settings but it's probably
""            a bit of a security risk.
""
"" Ok, here's how it works:
""
""   I use echo to send a dopey little MosRepl script (see below)
""   to Firefox.  Netcat (nc) has a nice option to disconnect
""   after 1 second (-q 1), so I'm using that.  All the output
""   is tossed away (2>&1 > /dev/null) because MozRepl is chatty.
""
""   Global variables are used (vimXo, vimYo) to capture the X and Y
""   offset of the web page for vim.   Maybe there's a way to not use
""   a global, but I don't know that that might be.  Anyway, after saving
""   the buffer and reloading the browser, scroll to the proper  X,Y offset.
""
"" See also:
""   http://wiki.github.com/bard/mozrepl/tutorial
""   http://forums.whirlpool.net.au/forum-replies-archive.cfm/495300.html
""
"" Aside:  Line continuation in vimscript is a bit weird;
""         it comes at start of the line you want merged,
""         rather than at the end of the line being broken.
""-------------------------------------------------------------------------- --------------------------
"function! Refresh_firefox()
"    if &modified
"        write
"        silent !echo  'vimYo = content.window.pageYOffset;
"                     \ vimXo = content.window.pageXOffset;
"                     \ BrowserReload();
"                     \ content.window.scrollTo(vimXo,vimYo);
"                     \ repl.quit();'  |
"                     \ nc localhost 4242 2>&1 > /dev/null
"    endif
"endfunction
"
"" everbird's hack
"function! Force_refresh_firefox()
"    silent !echo  'vimYo = content.window.pageYOffset;
"                 \ vimXo = content.window.pageXOffset;
"                 \ BrowserReload();
"                 \ content.window.scrollTo(vimXo,vimYo);
"                 \ repl.quit();'  |
"                 \ nc localhost 4242 2>&1 > /dev/null
"endfunction
"
"function! Restartweb_shadow_reading()
"    !ssh everbird@shadow "cd reading;make restartweb"
"endfunction
"
"function! Restartweb_shadow_shire()
"    !ssh everbird@shadow "cd shire;make restartweb"
"endfunction

"nmap <F6> :call Force_refresh_firefox()<CR>
"nmap <F7> :call Restartweb_shadow_reading()<CR>

"" Now I'm using VisualMark for bookmark instead of below
"" sign settings
"sign define siv text=>> texthl=MoreMsg linehl=ModeMsg
"nmap <leader>sv :exe ":sign place 1 line=" . line('.') . " name=siv file=" . expand("%:p")<cr>
"nmap <leader>jsv :exe ":sign jump 1 file=" . expand("%:p")<cr>
"nmap <leader>sS :sign unplace *<cr>
"nmap <leader>sV :sign unplace 1<cr>

" settings for tagbar
nnoremap <silent> <F4> :TagbarToggle<CR>
let g:tagbar_ctags_bin = '/usr/local/bin/ctags'
let g:tagbar_width = 30

" settings for gundo
nnoremap <silent> <F6> :GundoToggle<CR>

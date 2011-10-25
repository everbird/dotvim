call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

filetype on " enables filetype detection
filetype plugin on " enables filetype specific plugins

"set mouse=a

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

" for MacVim
"set lines=42 columns=160
"set :filetype plugin on

syntax on
set hlsearch
set hidden

colorscheme desert

set go-=T
set bg=dark
if &background == "dark"
    hi normal guibg=black
    " for MacVim
    "set transp=8
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

"nnoremap <silent> <F3> :Grep<CR>

""-----------------------------------------------------------------------------
"" lookupfile.vim 插件设置
""-----------------------------------------------------------------------------
"let g:LookupFile_MinPatLength = 2               "最少输入2个字符才开始查找
"let g:LookupFile_PreserveLastPattern = 0        "不保存上次查找的字符串
"let g:LookupFile_PreservePatternHistory = 1     "保存查找历史
"let g:LookupFile_AlwaysAcceptFirst = 1          "回车打开第一个匹配项目
"let g:LookupFile_AllowNewFiles = 0              "不允许创建不存在的文件
"let g:LookupFile_SortMethod = ""                "关闭对搜索结果的字母排序
"if filereadable("/Users/everbird/shadow/reading/filenametags")                "设置tag文件的名字
"let g:LookupFile_TagExpr ='"/Users/everbird/shadow/reading/filenametags"'
"endif

if has("autocmd")
    filetype plugin indent on
endif

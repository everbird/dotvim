" Exact plugin revisions are shared by Vim, Neovim, and the installer.
let g:dotvim_loaded_plugins = []
let g:dotvim_skipped_plugins = []
let g:dotvim_package_loader = 'disabled (basic profile or --noplugin)'
let g:dotvim_lsp_status = 'disabled (opt in with g:dotvim_lsp)'
if g:dotvim_profile !=# 'full' || (!&loadplugins && !get(g:, 'dotvim_installing', 0))
    finish
endif
if !filereadable(g:dotvim_root . '/autoload/plug.vim')
    call add(g:dotvim_skipped_plugins, 'vim-plug: autoload/plug.vim is missing')
    finish
endif

let s:installing = get(g:, 'dotvim_installing', 0)
let g:dotvim_package_loader = 'vim-plug'
" Git is needed for installation, but existing pure Vimscript plugins work without it.
silent! call plug#begin(g:dotvim_root . '/plugged')

function! s:Plugin(repo, name, commit, supported, requirement) abort
    let options = {'as': a:name, 'commit': a:commit}
    if s:installing || !a:supported
        " Keep every pin registered for PlugInstall/PlugClean, without loading it.
        let options.on = []
    endif
    execute 'Plug ' . string(a:repo) . ', ' . string(options)
    if s:installing
        return 0
    elseif !a:supported
        call add(g:dotvim_skipped_plugins, a:name . ': ' . a:requirement)
        return 0
    elseif empty(glob(g:plugs[a:name].dir . '/*'))
        call add(g:dotvim_skipped_plugins, a:name . ': not installed (run bootstrap.sh --full)')
        return 0
    endif
    call add(g:dotvim_loaded_plugins, a:name)
    return 1
endfunction

" repeat v1.2 supports Vim 7; current upstream requires Vim 8.
call s:Plugin('tpope/vim-repeat', 'repeat', '8106e142dfdc278ff3eaaadd7b362ad7949d4357', 1, '')
call s:Plugin('tpope/vim-surround', 'surround', '3d188ed2113431cf8dac77be61b842acb64433d9', 1, '')
call s:Plugin('preservim/nerdcommenter', 'nerdcommenter', 'a462bbda1e26f44fb3d3eb9d9d1c6a07aa98e665', 1, '')
call s:Plugin('preservim/nerdtree', 'nerdtree', '690d061b591525890f1471c6675bcb5bdc8cdff9', 1, '')
call s:Plugin('joshdick/onedark.vim', 'onedark', '47bec7a6196a843dad195d2666c3ac84c6e80c78', 1, '')
if s:Plugin('junegunn/vim-easy-align', 'easyalign', '9815a55dbcd817784458df7a18acacc6f82b1241', 1, '')
    xmap <Enter> <Plug>(EasyAlign)
    nmap <Leader>a <Plug>(EasyAlign)
endif
call s:Plugin('tpope/vim-fugitive', 'fugitive', '3b753cf8c6a4dcde6edee8827d464ba9b8c4a6f0', executable('git'), 'Git is required')
let g:NERDTreeWinPos = 'left'
let g:tagbar_width = 30

" BSD ctags (including /usr/bin/ctags on macOS) cannot power Tagbar.
function! s:Ctags() abort
    if s:installing
        return 0
    endif
    for candidate in (exists('g:dotvim_ctags') ? [g:dotvim_ctags] : ['ctags', 'ctags-universal', 'uctags'])
        if executable(candidate)
            let ctags_version = system(shellescape(candidate) . ' --version')
            if !v:shell_error && ctags_version =~# 'Universal Ctags'
                let g:tagbar_ctags_bin = candidate
                return 1
            endif
        endif
    endfor
    return 0
endfunction
call s:Plugin('preservim/tagbar', 'tagbar', '07cb8247487208124978daff8e13624667635457', s:Ctags(), 'Universal Ctags is required; set g:dotvim_ctags for a custom path')
call s:Plugin('mbbill/undotree', 'undotree', '6fa6b57cda8459e1e4b2ca34df702f55242f4e4d', has('persistent_undo') && executable('diff'), 'persistent undo and diff are required')

" Check the executable before loading fzf so it never offers a binary download.
let s:fzf = 0
if !s:installing && (has('nvim') || v:version >= 800) && executable('fzf')
    let s:version = matchstr(system('fzf --version'), '\d\+\.\d\+')
    if !v:shell_error && !empty(s:version)
        let s:parts = split(s:version, '\.')
        let s:fzf = str2nr(s:parts[0]) > 0 || str2nr(s:parts[1]) >= 63
    endif
endif
let s:fzf_loaded = s:Plugin('junegunn/fzf', 'fzf', '55c122f1a0e1340546c8709682bea5561fe0e8fd', s:fzf, 'Vim 8+ or Neovim, and fzf 0.63+ are required')
if s:Plugin('junegunn/fzf.vim', 'fzf-vim', '023de3c0e158ff9c2b0992175af10be97c2f2158', s:fzf, 'Vim 8+ or Neovim, and fzf 0.63+ are required') && s:fzf_loaded
    nnoremap <silent> <C-p> :Files<CR>
endif

" Personal UltiSnips remain opt-in because they use Python interpolation.
let g:UltiSnipsListSnippets = '<F8>'
let g:UltiSnipsJumpForwardTrigger = '<C-j>'
let g:UltiSnipsJumpBackwardTrigger = '<C-k>'
let g:UltiSnipsSnippetDirectories = ['UltiSnips', 'snippets']
let s:snippets = !s:installing && get(g:, 'dotvim_snippets', 0)
call s:Plugin('SirVer/ultisnips', 'ultisnips', '0ca6a21386021e74a91034365809dcca56ed13f0', s:snippets && (has('nvim') || v:version >= 802) && has('python3'), 'opt in with g:dotvim_snippets; Vim 8.2+ with Python 3, or a Neovim Python provider, is required')

let s:vim_lsp = !s:installing && get(g:, 'dotvim_lsp', 0) && !has('nvim') && has('vim9script') && has('job') && has('channel')
let s:lsp_loaded = s:Plugin('yegappan/lsp', 'lsp', 'c741b2f1afb42b9f267824dac4049674908f4a41', s:vim_lsp, 'opt in with g:dotvim_lsp on Vim 9+ with jobs/channels; Neovim uses its built-in client')
if s:installing
    finish
endif
if get(g:, 'dotvim_lsp', 0)
    if has('nvim-0.11') || s:lsp_loaded
        " Configure Vim LSP globals before plug#end can source plugin scripts.
        execute 'source ' . fnameescape(g:dotvim_root . '/lsp.vim')
    elseif has('nvim') || !s:vim_lsp
        let g:dotvim_lsp_status = 'requires Vim 9+ with jobs/channels or Neovim 0.11+'
    else
        let g:dotvim_lsp_status = 'Vim LSP plugin is not installed'
    endif
endif
call plug#end()

" Servers are optional executables on PATH; nothing is downloaded by the editor.
let s:defaults = [
    \ {'name': 'pylsp', 'cmd': ['pylsp'], 'filetypes': ['python'], 'root_markers': ['pyproject.toml', 'setup.py', '.git']},
    \ {'name': 'gopls', 'cmd': ['gopls'], 'filetypes': ['go', 'gomod'], 'root_markers': ['go.work', 'go.mod', '.git']},
    \ {'name': 'clangd', 'cmd': ['clangd'], 'filetypes': ['c', 'cpp'], 'root_markers': ['compile_commands.json', 'compile_flags.txt', '.git']},
    \ {'name': 'rust_analyzer', 'cmd': ['rust-analyzer'], 'filetypes': ['rust'], 'root_markers': ['Cargo.toml', '.git']},
    \ {'name': 'typescript', 'cmd': ['typescript-language-server', '--stdio'], 'filetypes': ['javascript', 'javascriptreact', 'typescript', 'typescriptreact'], 'root_markers': ['tsconfig.json', 'package.json', '.git']}
    \ ]
let g:dotvim_lsp_servers = get(g:, 'dotvim_lsp_servers', s:defaults)
if has('nvim')
    execute 'luafile ' . fnameescape(g:dotvim_root . '/nvim/lsp.lua')
else
    let g:lsp_options = {'autoComplete': 1, 'showDiagWithVirtualText': 0}
    let g:lsp_servers = []
    for s:server in g:dotvim_lsp_servers
        if executable(s:server.cmd[0])
            call add(g:lsp_servers, {
                \ 'name': s:server.name,
                \ 'filetype': s:server.filetypes,
                \ 'path': exepath(s:server.cmd[0]),
                \ 'args': s:server.cmd[1:],
                \ 'rootSearch': s:server.root_markers + (index(s:server.root_markers, '.git') >= 0 ? ['.git/'] : [])
                \ })
        endif
    endfor
    let g:dotvim_lsp_status = 'Vim LSP: ' . len(g:lsp_servers) . ' available server(s)'
    augroup dotvim_lsp
        autocmd!
        for s:server in g:lsp_servers
            execute 'autocmd FileType ' . join(s:server.filetype, ',') . ' nnoremap <silent><buffer> <Leader>gd :LspGotoDefinition<CR>'
            execute 'autocmd FileType ' . join(s:server.filetype, ',') . ' nnoremap <silent><buffer> <Leader>gh :LspHover<CR>'
            execute 'autocmd FileType ' . join(s:server.filetype, ',') . ' nnoremap <silent><buffer> <Leader>gr :LspShowReferences<CR>'
        endfor
    augroup END
endif

-- Use Neovim's built-in LSP; no Lua plugin manager or completion framework.
local group = vim.api.nvim_create_augroup('dotvim_lsp', { clear = true })
vim.api.nvim_create_autocmd('LspAttach', {
  group = group,
  callback = function(event)
    local options = { buffer = event.buf, silent = true }
    vim.keymap.set('n', '<Leader>gd', vim.lsp.buf.definition, options)
    vim.keymap.set('n', '<Leader>gh', vim.lsp.buf.hover, options)
    vim.keymap.set('n', '<Leader>gr', vim.lsp.buf.references, options)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    end
  end,
})

local available = 0
for _, server in ipairs(vim.g.dotvim_lsp_servers) do
  if vim.fn.executable(server.cmd[1]) == 1 then
    vim.lsp.config('dotvim_' .. server.name, {
      cmd = server.cmd,
      filetypes = server.filetypes,
      root_markers = server.root_markers,
    })
    vim.lsp.enable('dotvim_' .. server.name)
    available = available + 1
  end
end
vim.g.dotvim_lsp_status = 'Neovim built-in LSP: ' .. available .. ' available server(s)'

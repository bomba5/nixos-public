require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "clangd" }
vim.lsp.enable(servers)

vim.diagnostic.config({
  virtual_text = false,
})

-- read :h vim.lsp.config for changing options of lsp servers 

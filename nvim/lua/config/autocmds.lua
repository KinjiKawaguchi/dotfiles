-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Disable spell check for all filetypes
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    vim.cmd("setlocal nospell")
  end,
})

-- Check for file changes when focus returns or cursor is idle
vim.api.nvim_create_autocmd({ "FocusGained", "CursorHold" }, {
  command = "checktime",
})

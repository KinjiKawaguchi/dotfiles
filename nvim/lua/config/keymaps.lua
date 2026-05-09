-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- jj to escape insert mode
vim.keymap.set("i", "jj", "<Esc>", { desc = "Escape insert mode" })

-- Disable LazyVim default Alt+j/k line move
-- Esc直後に矢印キーを押すとAlt+j/kとして誤解釈され行が移動する問題を防止
vim.keymap.del("n", "<A-j>")
vim.keymap.del("n", "<A-k>")
vim.keymap.del("i", "<A-j>")
vim.keymap.del("i", "<A-k>")
vim.keymap.del("v", "<A-j>")
vim.keymap.del("v", "<A-k>")

-- Ctrl+a to select all
vim.keymap.set("n", "<C-a>", "ggVG", { desc = "Select all" })

-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable scroll animation
vim.g.snacks_animate_scroll = false

-- Disable spell check globally
vim.opt.spell = false

-- Auto-reload files changed by external processes
vim.o.autoread = true

if os.getenv("SSH_TTY") then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = osc52.paste("+"),
      ["*"] = osc52.paste("*"),
    },
  }
  -- LazyVim は SSH 時に clipboard を空にするので、OSC 52 を使う場合は再度有効化
  vim.opt.clipboard = "unnamedplus"
end


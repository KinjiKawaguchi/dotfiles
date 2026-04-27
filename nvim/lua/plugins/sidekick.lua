return {
  -- sidekick.nvim: AI sidekick for Neovim with Claude Code integration
  {
    "folke/sidekick.nvim",
    event = "VeryLazy",
    opts = {
      cli = {
        mux = {
          backend = "tmux",
          enabled = true,
        },
        tools = {
          claude = {
            cmd = { "claude" },
          },
        },
      },
    },
    keys = {
      -- Next Edit Suggestions
      {
        "<tab>",
        function()
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>"
          end
        end,
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
      -- CLI Terminal
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle()
        end,
        desc = "Toggle Sidekick",
      },
      {
        "<leader>as",
        function()
          require("sidekick.cli").select()
        end,
        desc = "Select AI Tool",
      },
      {
        "<leader>ac",
        function()
          require("sidekick.cli").toggle({ name = "claude", focus = true })
        end,
        desc = "Claude Code",
      },
      {
        "<leader>ad",
        function()
          require("sidekick.cli").close()
        end,
        desc = "Close Sidekick",
      },
      -- Send context
      {
        "<leader>at",
        function()
          require("sidekick.cli").send()
        end,
        mode = { "n", "v" },
        desc = "Send to Sidekick",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").file()
        end,
        desc = "Send File",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
        end,
        desc = "Select Prompt",
      },
    },
  },

  -- Copilot LSP (required for Next Edit Suggestions)
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
    },
    config = function(_, opts)
      require("copilot").setup(opts)
      -- Enable Copilot LSP for sidekick.nvim
      vim.lsp.enable("copilot")
    end,
  },
}

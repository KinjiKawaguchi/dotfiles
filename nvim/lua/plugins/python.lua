return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = false,
        pyrefly = {
          init_options = {
            diagnosticMode = "workspace",
          },
        },
      },
    },
  },
}

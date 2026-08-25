return {
  "nvim-treesitter/nvim-treesitter",
  -- snacks.image が Markdown 中の LaTeX 数式を切り出すのに latex parser を使う
  opts = { ensure_installed = { "latex" } },
}

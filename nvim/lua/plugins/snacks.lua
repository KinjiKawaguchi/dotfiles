return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true, -- 隠しファイル（.で始まるファイル）を表示
          ignored = true, -- .gitignoreで無視されているファイルを表示
        },
      },
    },
  },
}

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      -- 基本設定
      size = function(term)
        if term.direction == "horizontal" then
          return 17 -- 水平分割時の高さ
        elseif term.direction == "vertical" then
          return vim.o.columns * 2.4 -- 垂直分割時の幅
        end
      end,
      open_mapping = [[<c-t>]], -- トグルするためのキーマッピング
      direction = "float", -- デフォルトの開き方
      shade_terminals = true, -- 背景を暗くする
      start_in_insert = true, -- 開いた時にインサートモードに
      float_opts = {
        border = "curved", -- フロート時のボーダースタイル
      },
    },
  },
}

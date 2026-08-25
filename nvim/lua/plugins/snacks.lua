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
    indent = {
      scope = { enabled = false },
      chunk = { enabled = false },
    },
    image = {
      enabled = true,
      doc = {
        -- Markdown 等の画像リンクを本文中にインライン描画する
        inline = true,
        float = true,
        max_width = 60,
        max_height = 30,
      },
      -- $...$ を画像化する機能。latex parser があると有効になるが、
      -- 既定で数式の元テキストを conceal するため、描画に失敗すると
      -- 元テキストが隠れたまま placeholder だけが残り本文が壊れて見える。
      -- placeholder の前景色は画像 ID をそのまま RGB にした値なので、
      -- 端末が画像として解釈できないと任意の色の文字列として表示される。
      math = { enabled = false },
      convert = {
        magick = {
          -- 既定値の -trim はページを内容の外接矩形まで切り詰めるため、
          -- 用紙の縦横比が失われページごとに大きさが変わる。
          -- pdfview はページ寸法から行数を算出するので付けない。
          --
          -- 末尾の -density 96 は出力 PNG のメタデータだけを書き換える (再標本化はしない)。
          -- snacks はセル換算に size/dpi*96*scale を使うため、既定のまま
          -- ラスタ解像度と dpi が揃っていると相殺されてページが約 100 桁で頭打ちになる。
          -- dpi を小さく申告することで、指定した width/height が効く側に入る。
          pdf = {
            "-density",
            240,
            "{src}[{page}]",
            "-background",
            "white",
            "-alpha",
            "remove",
            "-units",
            "PixelsPerInch",
            "-density",
            96,
          },
        },
      },
    },
  },
}

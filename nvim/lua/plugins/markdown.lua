return {
  "iamcco/markdown-preview.nvim",
  optional = true,
  init = function()
    -- SSH 越しではサーバー側にブラウザがないため、URL を表示して
    -- 手元から `ssh -L 8090:localhost:8090` で転送して開く。
    vim.g.mkdp_port = "8090"
    vim.g.mkdp_echo_preview_url = 1
    -- 待ち受けは localhost のみに限定する
    vim.g.mkdp_open_to_the_world = 0
  end,
}

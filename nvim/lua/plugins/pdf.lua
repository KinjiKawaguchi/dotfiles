-- PDF ビューア。実装は lua/pdfview/ にある。
return {
  "folke/snacks.nvim",
  optional = true,
  init = function()
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("pdfview_attach", { clear = true }),
      -- snacks.image は対応形式のバッファに filetype=image を設定する。
      -- この時点ではまだ placement が張られていないため、schedule して
      -- snacks の初期描画が済んでから引き取る。
      pattern = "image",
      callback = function(event)
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(event.buf) then
            require("pdfview").attach(event.buf)
          end
        end)
      end,
    })
  end,
}

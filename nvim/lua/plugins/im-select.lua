-- Insert モードを抜けたら IME を自動で英数(ABC)に切り替える
-- macism はローカル macOS の入力ソース API を直接操作するため、SSH 先では無効化する
return {
  "keaising/im-select.nvim",
  cond = os.getenv("SSH_TTY") == nil,
  opts = {
    default_im_select = "com.apple.keylayout.ABC",
    default_command = "macism",
    ignore_unknown_im = true,
  },
}

-- PDF を全ページ連結して表示し、通常のバッファと同じ操作でスクロールできるようにする。
-- 各ページは layout が決めた行範囲に placement として重なり、
-- 表示範囲から外れたものは render 側で破棄される。

local Layout = require("pdfview.layout")
local Render = require("pdfview.render")

local M = {}

---@type table<integer, table>
local sessions = {}

---ズームの上限。ウィンドウの表示領域と、placeholder が扱えるセル数の小さい方。
---@param buf integer
---@param doc table
---@return integer
local function max_cols(buf, doc)
  local win = vim.fn.bufwinid(buf)
  local available = vim.o.columns
  if win ~= -1 then
    local info = vim.fn.getwininfo(win)[1]
    available = info.width - info.textoff
  end
  return math.max(Layout.MIN_COLS, math.min(available, Layout.limit_cols(doc)))
end

---番号欄や折り返しがあると表示幅が変わり、右端が欠ける。
---snacks が画像バッファ用に持っている設定をそのまま適用する。
---@param buf integer
local function apply_wo(buf)
  local win = vim.fn.bufwinid(buf)
  if win ~= -1 then
    Snacks.util.wo(win, Snacks.image.config.wo or {})
  end
end

---@param session table
local function fill(session)
  local lines = {}
  for i = 1, Layout.total_lines(session.layout) do
    lines[i] = ""
  end
  vim.bo[session.buf].modifiable = true
  vim.api.nvim_buf_set_lines(session.buf, 0, -1, false, lines)
  vim.bo[session.buf].modifiable = false
  vim.bo[session.buf].modified = false
end

---@param session table
local function update_winbar(session)
  local win = vim.fn.bufwinid(session.buf)
  if win == -1 then
    return
  end
  local page = Layout.locate(session.layout, vim.api.nvim_win_get_cursor(win)[1])
  local label = (" %s   %d / %d   幅 %d 桁 "):format(
    vim.fn.fnamemodify(session.file, ":t"),
    page,
    session.layout.pages,
    session.layout.cols
  )
  vim.api.nvim_set_option_value("winbar", label:gsub("%%", "%%%%"), { scope = "local", win = win })
end

---桁幅を変えてページ配置を組み直す。カーソルのある文書上の位置を保つ。
---@param session table
---@param cols integer
local function relayout(session, cols)
  local win = vim.fn.bufwinid(session.buf)
  local page, fraction = 1, 0
  if win ~= -1 then
    page, fraction = Layout.locate(session.layout, vim.api.nvim_win_get_cursor(win)[1])
  end

  Render.clear(session)
  session.layout = Layout.build(session.doc, cols)
  fill(session)

  if win ~= -1 then
    local row = Layout.page_row(session.layout, page) + math.floor(fraction * session.layout.block)
    row = math.max(1, math.min(row, Layout.total_lines(session.layout)))
    vim.api.nvim_win_set_cursor(win, { row, 0 })
  end
  Render.sync(session)
  update_winbar(session)
end

---@param buf integer
---@param delta integer
function M.zoom(buf, delta)
  local session = sessions[buf]
  if not session then
    return
  end
  local cols = math.max(Layout.MIN_COLS, math.min(session.layout.cols + delta, max_cols(buf, session.doc)))
  if cols ~= session.layout.cols then
    relayout(session, cols)
  end
end

---ウィンドウ幅にページ幅を合わせる
---@param buf integer
function M.fit(buf)
  local session = sessions[buf]
  if session then
    relayout(session, max_cols(buf, session.doc))
  end
end

---@param buf integer
---@param resolve fun(page: integer, pages: integer): integer
function M.goto_page(buf, resolve)
  local session = sessions[buf]
  local win = session and vim.fn.bufwinid(buf) or -1
  if win == -1 then
    return
  end
  local current = Layout.locate(session.layout, vim.api.nvim_win_get_cursor(win)[1])
  local page = math.max(1, math.min(resolve(current, session.layout.pages), session.layout.pages))
  vim.api.nvim_win_set_cursor(win, { Layout.page_row(session.layout, page), 0 })
  vim.cmd("normal! zt")
  Render.sync(session)
  update_winbar(session)
end

---本文を pdftotext で抜き出して別タブに開く
---@param buf integer
function M.extract_text(buf)
  local session = sessions[buf]
  if not session then
    return
  end
  local lines = vim.fn.systemlist({ "pdftotext", "-layout", session.file, "-" })
  if vim.v.shell_error ~= 0 then
    Snacks.notify.error("pdftotext に失敗しました")
    return
  end
  vim.cmd.tabnew()
  local text_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(text_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_name(text_buf, session.file .. " [text]")
  Snacks.util.bo(text_buf, {
    buftype = "nofile",
    filetype = "text",
    modifiable = false,
    modified = false,
    swapfile = false,
  })
end

---@param session table
local function setup_autocmds(session)
  local group = vim.api.nvim_create_augroup("pdfview_" .. session.buf, { clear = true })
  vim.api.nvim_create_autocmd({ "WinScrolled", "CursorMoved" }, {
    group = group,
    buffer = session.buf,
    callback = function()
      Render.sync(session)
      update_winbar(session)
    end,
  })
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = group,
    buffer = session.buf,
    callback = function()
      if session.layout.cols > max_cols(session.buf, session.doc) then
        relayout(session, max_cols(session.buf, session.doc))
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    buffer = session.buf,
    callback = function()
      apply_wo(session.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = session.buf,
    callback = function()
      Render.clear(session)
      sessions[session.buf] = nil
    end,
  })
end

---実機でしか分からない寸法を突き合わせるための診断出力
---@param buf integer
function M.debug(buf)
  local session = sessions[buf]
  if not session then
    Snacks.notify.warn("pdfview のセッションがありません")
    return
  end
  local win = vim.fn.bufwinid(buf)
  local info = win ~= -1 and vim.fn.getwininfo(win)[1] or {}
  local term = Snacks.image.terminal.size()
  local env = Snacks.image.terminal.env()
  local pages = vim.tbl_keys(session.placements)
  table.sort(pages)

  local out = {
    ("端末     %s  placeholders=%s remote=%s"):format(env.name, tostring(env.placeholders), tostring(env.remote)),
    ("セル     %dx%d px  scale=%s"):format(term.cell_width, term.cell_height, tostring(term.scale)),
    ("窓       幅%s 高%s textoff=%s"):format(info.width, info.height, info.textoff),
    ("用紙     %gx%g pt  描画上限 %d 桁"):format(
      session.doc.width,
      session.doc.height,
      Layout.limit_cols(session.doc)
    ),
    ("配置     %d 桁 x %d 行  余白%d行  総行数%d"):format(
      session.layout.cols,
      session.layout.rows,
      Layout.GAP,
      Layout.total_lines(session.layout)
    ),
    ("描画中   ページ %s"):format(table.concat(vim.tbl_map(tostring, pages), ", ")),
  }
  local sample = session.placements[pages[1]]
  if sample then
    local ok, state = pcall(sample.state, sample)
    if ok then
      out[#out + 1] = ("実寸     %d 桁 x %d 行"):format(state.loc.width, state.loc.height)
    end
  end
  Snacks.notify(table.concat(out, "\n"), { title = "pdfview" })
end

---@param buf integer
local function setup_keymaps(buf)
  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
  end
  map("]p", function()
    M.goto_page(buf, function(page)
      return page + 1
    end)
  end, "次のページ")
  map("[p", function()
    M.goto_page(buf, function(page)
      return page - 1
    end)
  end, "前のページ")
  map("]P", function()
    M.goto_page(buf, function(_, pages)
      return pages
    end)
  end, "最終ページ")
  map("[P", function()
    M.goto_page(buf, function()
      return 1
    end)
  end, "先頭ページ")
  map("+", function()
    M.zoom(buf, 10)
  end, "拡大")
  map("-", function()
    M.zoom(buf, -10)
  end, "縮小")
  map("=", function()
    M.fit(buf)
  end, "幅をウィンドウに合わせる")
  map("<leader>pg", function()
    vim.ui.input({ prompt = "ページ番号: " }, function(input)
      local page = tonumber(input)
      if page then
        M.goto_page(buf, function()
          return page
        end)
      end
    end)
  end, "ページ番号を指定して移動")
  map("<leader>pt", function()
    M.extract_text(buf)
  end, "テキストを抽出して開く")
end

---@param buf integer
function M.attach(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  if sessions[buf] or file:lower():sub(-4) ~= ".pdf" or vim.fn.filereadable(file) == 0 then
    return
  end
  local doc = Layout.probe(file)
  if not doc then
    return
  end

  -- snacks が張った 1 ページ目の placement を引き取る
  Snacks.image.placement.clean(buf)

  -- 桁幅を測る前に番号欄を消しておかないと、表示領域を取り違える
  apply_wo(buf)

  local session = { buf = buf, file = file, doc = doc, placements = {} }
  session.layout = Layout.build(doc, max_cols(buf, doc))
  sessions[buf] = session

  fill(session)
  setup_autocmds(session)
  setup_keymaps(buf)
  vim.api.nvim_buf_create_user_command(buf, "PdfviewDebug", function()
    M.debug(buf)
  end, { desc = "pdfview の実測値を表示する" })
  Render.sync(session)
  update_winbar(session)
end

return M

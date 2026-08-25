-- 表示範囲に近いページだけ placement を張り、離れたものは破棄する (仮想化)。

local Layout = require("pdfview.layout")

local M = {}

---@param session table
---@param page integer
local function place(session, page)
  local layout = session.layout
  local row = Layout.page_row(layout, page)
  local ok, placement = pcall(Snacks.image.placement.new, session.buf, ("%s#page=%d"):format(session.file, page), {
    pos = { row, 0 },
    -- range を明示しないと 1 行分しか実行に重ならず、残りが virt_lines になって
    -- 行数とページ位置がずれる
    range = { row, 0, row + layout.rows - 1, 0 },
    conceal = true,
    -- inline を立てないと snacks が「1 画像 = 1 バッファ」前提の動作をする。
    -- 具体的には更新のたびに winrestview で先頭行に戻し、変換中はバッファを
    -- 空にし、fallback 描画では namespace ごと消すため、複数ページを並べられない。
    inline = true,
    width = layout.cols,
    height = layout.rows,
    auto_resize = false,
  })
  if ok then
    session.placements[page] = placement
  end
end

---@param session table
---@param page integer
local function unplace(session, page)
  local placement = session.placements[page]
  if placement then
    pcall(function()
      placement:close()
    end)
    session.placements[page] = nil
  end
end

---すべての placement を破棄する
---@param session table
function M.clear(session)
  for page in pairs(session.placements) do
    unplace(session, page)
  end
end

---表示範囲の前後 1 ページ分をマージンとして描画対象を決める
---@param session table
---@return integer|nil from, integer|nil to
local function visible_pages(session)
  local win = vim.fn.bufwinid(session.buf)
  if win == -1 then
    return nil, nil
  end
  local margin = session.layout.block
  local first = math.max(1, vim.fn.line("w0", win) - margin)
  local last = vim.fn.line("w$", win) + margin
  local from = Layout.locate(session.layout, first)
  local to = Layout.locate(session.layout, last)
  return from, to
end

---@param session table
function M.sync(session)
  if not vim.api.nvim_buf_is_valid(session.buf) then
    return
  end
  local from, to = visible_pages(session)
  if not from then
    return
  end
  for page in pairs(session.placements) do
    if page < from or page > to then
      unplace(session, page)
    end
  end
  for page = from, to do
    if not session.placements[page] then
      place(session, page)
    end
  end
end

return M

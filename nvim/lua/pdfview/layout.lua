-- ページを縦に連結したときの行配置を計算する。
-- 1 ページは rows 行を占め、ページ間に GAP 行の余白を挟む。

local M = {}

M.GAP = 2
M.MIN_COLS = 20

---PDF のページ数と用紙寸法 (pt) を取得する
---@param file string
---@return { pages: integer, width: number, height: number }|nil
function M.probe(file)
  local out = vim.fn.system({ "pdfinfo", file })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local pages = tonumber(out:match("Pages:%s+(%d+)"))
  local width, height = out:match("Page size:%s+([%d%.]+)%s+x%s+([%d%.]+)")
  if not (pages and width and height) then
    return nil
  end
  return { pages = pages, width = tonumber(width), height = tonumber(height) }
end

---unicode placeholder は行・列を結合分音記号で符号化しており、使える記号は 297 種。
---1 つの placement がこれを超える桁数・行数を持つと、超えた分は描画されず欠ける。
M.MAX_CELLS = 297

---snacks が実際に返すセル寸法を問い合わせる。縦横比の計算を自前で持つと
---snacks 側の丸めと 1 行ずれて余白や重なりになるため、同じ関数に聞く。
---変換後のラスタは十分大きく fit は必ず box へ縮める側に入るので、
---info には用紙比を保ったまま十分大きい寸法を渡す。
---@param doc { width: number, height: number }
---@param box { width: integer, height: integer }
---@return { width: integer, height: integer }
local function fit(doc, box)
  return Snacks.image.util.fit("", box, {
    info = { size = { width = doc.width * 10, height = doc.height * 10 }, dpi = { width = 72, height = 72 } },
  })
end

---placeholder の制約から決まる桁幅の上限。縦も 297 に収まるところまで下げる。
---@param doc { width: number, height: number }
---@return integer
function M.limit_cols(doc)
  local size = fit(doc, { width = M.MAX_CELLS, height = M.MAX_CELLS })
  return math.max(M.MIN_COLS, size.width)
end

---要求した桁幅が上限を超えていれば、実際に描かれる寸法まで切り下げる。
---@param doc { pages: integer, width: number, height: number }
---@param cols integer 1 ページの横幅 (セル)
---@return { pages: integer, cols: integer, rows: integer, block: integer }
function M.build(doc, cols)
  local size = fit(doc, { width = cols, height = 9999 })
  local rows = math.max(1, size.height)
  return { pages = doc.pages, cols = size.width, rows = rows, block = rows + M.GAP }
end

---@param layout table
---@return integer
function M.total_lines(layout)
  return layout.pages * layout.block
end

---ページ n の先頭行 (1-indexed)
---@param layout table
---@param page integer
---@return integer
function M.page_row(layout, page)
  return (page - 1) * layout.block + 1
end

---行番号から、その行が属するページと、ページ内の相対位置 (0..1) を求める
---@param layout table
---@param row integer
---@return integer page, number fraction
function M.locate(layout, row)
  local index = math.max(0, row - 1)
  local page = math.min(layout.pages, math.floor(index / layout.block) + 1)
  local fraction = (index % layout.block) / layout.block
  return page, fraction
end

return M

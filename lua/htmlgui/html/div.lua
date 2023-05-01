local a = vim.api
local ts = vim.treesitter
local map = vim.keymap.set
local utils = require("htmlgui.utils")

local M = {}

function M.get_width_height(win)
  local width = a.nvim_win_get_width(win)
  local height = a.nvim_win_get_height(win)
  return { width = width, height = height }
end

function M.parse_div(node, buf)
  local div = { node = node }
  -- node:type() = element
  local tag = node:child()
  local nattrs = tag:named_child_count() -- start_tag
  local attrs = {}
  for i = 1, nattrs - 1 do
    -- HACK: unfortunately, not sure how to use treesitter here
    local attr = tag:named_child(i)
    local attr_key = ts.get_node_text(attr:named_child(0), buf)
    local attr_value = ts.get_node_text(attr:named_child(1):named_child(0), buf)
    attrs[attr_key] = utils.clean_up_text(attr_value)
  end
  div.attrs = attrs

  local tagname = (ts.get_node_text(tag:named_child(), buf))
  div.tag = tagname

  -- if ul, then put in temp buffer and parse with ts
  -- BUG: only gets first line, need to get range from start and end tags
  if tagname == "ul" then
    -- get relevant lines
    local text = ts.get_node_text(div.node, buf)
    local lines = vim.split(utils.clean_up_text(text, false, "\n"), "\n")

    -- create temp buffer
    local temp_buf = a.nvim_create_buf(false, true)
    a.nvim_buf_set_lines(temp_buf, -1, -1, false, lines)

    -- get ul in temp_buf
    local lang = "html"
    local root = utils.get_root(temp_buf, lang)
    local ul = root:named_child(0)

    -- iterate to get li
    lines = {}
    for i = 1, vim.tbl_count(ul:named_children()) - 1 do
      local child = ul:named_child(i)
      for j = 1, vim.tbl_count(child:named_children()) - 2 do
        text = ts.get_node_text(child:named_child(j), temp_buf)
        table.insert(lines, text)
      end
    end

    -- clean up temp buffer
    a.nvim_buf_delete(temp_buf, { force = true })

    -- put into div
    local cool_items = {}
    for _, line in ipairs(lines) do
      table.insert(cool_items, string.format("  🍎  %s", line))
    end

    div.text = text
    div.lines = cool_items
  else
    div.text = ts.get_node_text(tag:next_named_sibling(), buf)
    div.lines = { div.text }
  end

  return div
end

function M.create_div(div, parent_win, app_config, app_state)
  -- create buffer with div text
  local buf = a.nvim_create_buf(false, true)
  a.nvim_buf_set_lines(buf, 0, -1, false, div.lines)

  -- this changes style as well?
  local style = div.attrs.style
  local size = M.get_width_height(parent_win)
  if style.col < 1 then
    style.col = math.ceil(size.width * style.col)
  end
  if style.row < 1 then
    style.row = math.ceil(size.height * style.row)
  end
  if style.height < 1 then
    style.height = math.ceil(size.height * style.height)
  end
  if style.width < 1 then
    style.width = math.ceil(size.width * style.width)
  end

  if style.zindex == nil then
    style.zindex = 10
  end

  local opts = {
    relative = "win",
    win = parent_win,
    col = style.col,
    row = style.row,
    width = style.width,
    height = style.height,
    zindex = style.zindex,
    style = "minimal",
  }
  local win = a.nvim_open_win(buf, true, opts)

  -- if href, then provide keymap
  if div.attrs.href ~= nil then
    map("n", "<enter>", function()
      require("htmlgui.layout").destroy(app_state)
      require("htmlgui.layout").setup(app_config, div.attrs.href)
    end, { buffer = buf })
  end

  return { div = div, win = win, buf = buf }
end

return M

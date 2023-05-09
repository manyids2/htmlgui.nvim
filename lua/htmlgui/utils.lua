local a = vim.api
local ts = vim.treesitter
local clock = os.clock
local parsers = require("nvim-treesitter.parsers")

local M = {}

function M.sleep(n)
  local t0 = clock()
  while clock() - t0 <= n do
  end
end

function M.shallow_copy(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end

function M.validate_config(config, default_config)
  -- create shallow copy of config, extend with defaults
  if config == nil then
    config = default_config
  end
  vim.validate({ config = { config, "table" } })
  config = vim.tbl_extend("keep", config, default_config)
  return M.shallow_copy(config)
end

function M.clean_up_text(text, remove_parens, sep)
  if sep == nil then
    sep = " "
  end
  if remove_parens then
    text = vim.trim(string.gsub(text, "{", ""))
    text = vim.trim(string.gsub(text, "}", ""))
  end
  local lines = vim.split(text, "\n")
  local clean = {}
  for _, line in pairs(lines) do
    table.insert(clean, vim.trim(line))
  end
  return table.concat(clean, sep)
end

function M.focus(win_name, state)
  if state[win_name] ~= nil then
    if state[win_name].win ~= nil then
      a.nvim_set_current_win(state[win_name].win)
    else
      vim.notify("Unknown name :" .. win_name, vim.log.levels.ERROR)
    end
  end
end

function M.mark_last_row(data, icon)
  local align = data.element.attrs.style.justify_content
  local height = a.nvim_win_get_height(data.win)
  local linenr = height - 1
  local colnr = 0
  if align == "bottom" then
    linenr = 0
  end
  local opts = {
    id = 1,
    end_col = 1,
    virt_text_pos = "overlay",
    virt_text = { { icon } },
  }

  -- BUG: Line gets overwritten
  -- a.nvim_win_set_height(data.win, size.height + 1)
  -- a.nvim_buf_set_lines(data.buf, -1, -1, false, { string.rep(" ", size.width) })
  local ns_id = a.nvim_create_namespace("mark_float")
  data.mark_id = a.nvim_buf_set_extmark(data.buf, ns_id, linenr, colnr, opts)
end

function M.get_width_height(win)
  local width = a.nvim_win_get_width(win)
  local height = a.nvim_win_get_height(win)
  return { width = width, height = height }
end

function M.get_win_opts(style, parent_win)
  -- this changes style as well?
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
  return opts
end

function M.lines_to_full_size(lines, size, style)
  local lheight = vim.tbl_count(lines)
  local wwidth = size.width
  local wheight = size.height
  local empty = string.rep(" ", size.width)
  local slines = {}

  -- get top and bottom padding
  local tpad, bpad
  if style.justify_content == "center" then
    tpad = math.ceil((wheight - lheight) / 2)
  elseif style.justify_content == "bottom" then
    tpad = wheight - lheight
  else -- default : top
    tpad = 0
  end

  for _ = 1, tpad, 1 do
    table.insert(slines, empty)
  end

  -- get left and right padding
  local lpad, rpad
  for _, line in pairs(lines) do
    local lwidth = vim.api.nvim_strwidth(line)
    if style.align_items == "center" then
      lpad = math.ceil((wwidth - lwidth) / 2)
      rpad = wwidth - lwidth - lpad
    elseif style.align_items == "right" then
      lpad = wwidth - lwidth
      rpad = 0
    else -- default : left
      lpad = 0
      rpad = wwidth - lwidth
    end
    local newline = string.rep(" ", lpad) .. line .. string.rep(" ", rpad)
    table.insert(slines, newline)
  end

  bpad = wheight - lheight - tpad
  for _ = 1, bpad, 1 do
    table.insert(slines, empty)
  end

  return slines
end

function M.get_root(buf, lang)
  if lang == nil then
    lang = "html"
  end
  local parser = parsers.get_parser(buf, lang)
  return parser:parse()[1]:root()
end

function M.get_text_from_range(range, buf)
  -- simple trim and concat
  local lines = a.nvim_buf_get_text(buf, range[1], range[2], range[3], range[4], {})
  local text = ""
  if vim.tbl_count(lines) > 1 then
    vim.tbl_map(function(line)
      text = text .. vim.trim(line)
    end, lines)
  else
    text = lines[1]
  end
  return text
end

function M.get_matches(query, root, buf, lang)
  local parsed_query = ts.query.parse(lang, query)
  local s, _, e, _ = root:range()
  local matches = {}
  for _, node, metadata in parsed_query:iter_captures(root, buf, s, e) do
    local ids = vim.tbl_keys(metadata)
    if vim.tbl_count(ids) > 0 then
      metadata = metadata[ids[1]]
    end
    table.insert(matches, { node = node, metadata = metadata })
  end
  return matches
end

function M.get_text_from_first_tag(query, root, buf, lang)
  local tt = M.get_matches(query, root, buf, lang)
  if vim.tbl_count(tt) > 0 then
    return M.get_text_from_range(tt[1].metadata.range, buf)
  end
end

function M.map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.append_shell_output(cmd, lines, header)
  local output = vim.fn.system(cmd)
  local olines = vim.split(output, "\n")
  if header ~= nil then
    table.insert(lines, "")
    table.insert(lines, " 🚀 Running : " .. cmd)
    table.insert(lines, "")
  end
  for _, oline in ipairs(olines) do
    table.insert(lines, oline)
  end
  return lines
end

return M

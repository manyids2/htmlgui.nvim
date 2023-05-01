local ts = vim.treesitter
local utils = require("htmlgui.utils")

local M = {}

M.queries = {
  classes = [[(
  class_selector
    ((class_name) @_name
    (#offset! @_name 0 0 0 0 ))
  )]],
}

M.default_style = {
  row = 0.1,
  col = 0.1,
  width = 0.8,
  height = 0.8,
  zindex = 20,
  color = "NormalFloat",
  align_items = "center",
  justify_content = "center",
}

M.type_numbers = { "row", "col", "height", "width", "zindex" }

function M.get_classes(root, buf, lang)
  local classes = {}
  local class_matches = utils.get_matches(M.queries.classes, root, buf, lang)
  for _, class_match in pairs(class_matches) do
    -- HACK: treesitter need help
    local ruleset_children = class_match.node:parent():parent():parent():named_children()
    local text = ""
    if vim.tbl_count(ruleset_children) == 2 then
      local block = ruleset_children[2]
      text = ts.get_node_text(block, buf)
      text = utils.clean_up_text(text, true)
    end
    -- return usable things
    local name = utils.get_text_from_range(class_match.metadata.range, buf)
    classes[name] = {
      match = class_match,
      text = text,
    }
  end
  return classes
end

function M.get_style_table(text)
  local style = {}
  local parts = vim.split(text, ";")
  for _, v in ipairs(parts) do
    local vv = vim.split(v, ":")
    if vim.tbl_count(vv) == 2 then
      local key = string.gsub(vim.trim(vv[1]), "-", "_")
      local value = vim.trim(vv[2])
      style[key] = value
    end
  end
  return style
end

function M.clean_up_style(style)
  for key, value in pairs(style) do
    if vim.tbl_contains(M.type_numbers, key) then
      style[key] = tonumber(value)
    else
      style[key] = value
    end
  end
  return style
end

function M.get_style_for_element(div, css)
  local style = {}
  -- for css, check class
  if div.attrs.class ~= nil then
    local name = div.attrs.class
    local css_style = {}
    if css.classes[name] ~= nil then
      css_style = M.get_style_table(css.classes[name].text)
    end

    -- add to style
    for key, value in pairs(css_style) do
      style[key] = value
    end
  end

  -- override with inline
  local inline_style = {}
  if div.attrs.style ~= nil then
    inline_style = M.get_style_table(div.attrs.style)
  end
  for key, value in pairs(inline_style) do
    style[key] = value
  end

  -- extend with defaults
  style = vim.tbl_extend("keep", style, M.default_style)
  style = M.clean_up_style(style)
  return style
end

return M

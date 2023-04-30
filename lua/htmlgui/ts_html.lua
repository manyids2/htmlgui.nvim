local a = vim.api
local ts = vim.treesitter
local parsers = require("nvim-treesitter.parsers")

local M = {}

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

function M.get_info(buf)
	-- get info from html buffer
	local root = M.get_root(buf)
	local title = M.get_title(root, buf)
	local script = M.get_script(root, buf)
	local style = M.get_style(root, buf)
	local filename = vim.fs.basename(a.nvim_buf_get_name(buf))
	local info = {
		root = root,
		title = title,
		script = script,
		style = style,
		filename = filename,
	}
	return info
end

function M.get_first_match(query, root, buf, lang)
	if lang == nil then
		lang = "html"
	end
	local parsed_query = ts.query.parse(lang, query)
	local s, _, e, _ = root:range()
	for _, node, metadata in parsed_query:iter_captures(root, buf, s, e) do
		local ids = vim.tbl_keys(metadata)
		if vim.tbl_count(ids) > 0 then
			metadata = metadata[ids[1]]
		end
		return { node = node, metadata = metadata }
	end
end

function M.get_all_matches(query, root, buf, lang)
	if lang == nil then
		lang = "html"
	end
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

function M.get_title(root, buf)
	local query = [[(
  element
    (start_tag (tag_name) @_head) (#eq? @_head "head")
    (element
      (start_tag (tag_name) @_title) (#eq? @_title "title")
      (text) @_text (#offset! @_text 0 0 0 0 ))
  )]]
	local tt = M.get_first_match(query, root, buf)
	return M.get_text_from_range(tt.metadata.range, buf)
end

function M.get_style(root, buf)
	local query = [[(
  element
    (start_tag (tag_name) @_head) (#eq? @_head "head")
    (element
      (self_closing_tag
        (tag_name) @_link
        (attribute
          (attribute_name) @_name
          (quoted_attribute_value (attribute_value) @_value))
  (#eq? @_link "link")
  (#eq? @_name "href")
  (#offset! @_value 0 0 0 0 )))
  )]]
	local tt = M.get_first_match(query, root, buf)
	return M.get_text_from_range(tt.metadata.range, buf)
end

function M.get_script(root, buf)
	local query = [[(
  script_element
    (start_tag
      (tag_name) @_script
      (attribute (quoted_attribute_value (attribute_value) @_value)))
  (#eq? @_script "script")
  (#offset! @_value 0 0 0 0 )
)]]
	local tt = M.get_first_match(query, root, buf)
	return M.get_text_from_range(tt.metadata.range, buf)
end

function M.get_body(buf)
	local root = M.get_root(buf)
	local query = [[(
  element
    (start_tag (tag_name) @_body)
    (#eq? @_body "body")
)]]
	local tt = M.get_first_match(query, root, buf)
	-- HACK: unfortunately, not sure how to use treesitter here
	return tt.node:parent():parent()
end

function M.get_divs(root, buf)
	local query = [[(
  element
    (start_tag (tag_name) @_div)
    (#eq? @_div "div")
)]]
	local tt = M.get_all_matches(query, root, buf)
	return tt
end

function M.parse_div(node, buf)
	local tag = node:child()
	local nattrs = tag:named_child_count() -- start_tag
	local attrs = {}
	for i = 1, nattrs - 1 do
		-- HACK: unfortunately, not sure how to use treesitter here
		local attr = tag:named_child(i)
		local attr_key = ts.get_node_text(attr:named_child(0), buf)
		local attr_value = ts.get_node_text(attr:named_child(1):named_child(0), buf)
		attrs[attr_key] = attr_value
	end
	local text = ts.get_node_text(tag:next_named_sibling(), buf)
	return { tag = "div", attrs = attrs, text = text }
end

function M.get_rect_from_div(div)
	-- parse div to get style, with sane defaults
	local rect = { row = 0.1, col = 0.1, width = 0.8, height = 0.8, zindex = 10 }
	local parts = vim.split(div.attrs.style, ";")
	for _, v in ipairs(parts) do
		local vv = vim.split(v, ":")
		if vim.tbl_count(vv) == 2 then
			rect[vim.trim(vv[1])] = tonumber(vim.trim(vv[2]))
		end
	end
	return rect
end

function M.get_width_height(win)
	local width = a.nvim_win_get_width(win)
	local height = a.nvim_win_get_height(win)
	return { width = width, height = height }
end

function M.create_div(div, parent_win)
	-- create buffer with div text
	local rect = M.get_rect_from_div(div)
	local buf = a.nvim_create_buf(false, true)
	a.nvim_buf_set_lines(buf, 0, -1, false, { div.text })

	local size = M.get_width_height(parent_win)
	if rect.col < 1 then
		rect.col = math.ceil(size.width * rect.col)
	end
	if rect.row < 1 then
		rect.row = math.ceil(size.height * rect.row)
	end
	if rect.height < 1 then
		rect.height = math.ceil(size.height * rect.height)
	end
	if rect.width < 1 then
		rect.width = math.ceil(size.width * rect.width)
	end

	if rect.zindex == nil then
		rect.zindex = 10
	end

	local opts = {
		relative = "win",
		win = parent_win,
		col = rect.col,
		row = rect.row,
		width = rect.width,
		height = rect.height,
		zindex = rect.zindex,
		style = "minimal",
	}
	local win = a.nvim_open_win(buf, true, opts)
	return { div = div, win = win, buf = buf }
end

return M

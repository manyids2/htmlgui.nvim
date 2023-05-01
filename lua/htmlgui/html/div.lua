local a = vim.api
local ts = vim.treesitter

local M = {}

function M.get_width_height(win)
	local width = a.nvim_win_get_width(win)
	local height = a.nvim_win_get_height(win)
	return { width = width, height = height }
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
	local rect = { row = 0.1, col = 0.1, width = 0.8, height = 0.8, zindex = 100 }
	local parts = vim.split(div.attrs.style, ";")
	for _, v in ipairs(parts) do
		local vv = vim.split(v, ":")
		if vim.tbl_count(vv) == 2 then
			rect[vim.trim(vv[1])] = tonumber(vim.trim(vv[2]))
		end
	end
	return rect
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

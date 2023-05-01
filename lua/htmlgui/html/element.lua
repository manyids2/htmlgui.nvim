local a = vim.api
local ts = vim.treesitter
local map = vim.keymap.set
local utils = require("htmlgui.utils")
local html_ul = require("htmlgui.html.ul")
local html_a = require("htmlgui.html.a")

local M = {}

function M.parse_element(node, buf)
	local element = { node = node }
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
	element.attrs = attrs

	local tagname = (ts.get_node_text(tag:named_child(), buf))
	element.tag = tagname

	-- if ul, then put in temp buffer and parse with ts
	-- BUG: only gets first line, need to get range from start and end tags
	if tagname == "ul" then
		-- get relevant lines
		element = html_ul.parse_ul(element, buf)
	else
		element.text = ts.get_node_text(tag:next_named_sibling(), buf)
		element.lines = { element.text }
	end

	return element
end

function M.create_win(element, buf, parent_win)
	local opts = utils.get_win_opts(element.attrs.style, parent_win)
	local win = a.nvim_open_win(buf, true, opts)
	return win
end

function M.set_keymaps(element, buf, app_state, app_config)
	if element.attrs.href ~= nil then
		html_a.set_keymaps(element, buf, app_state, app_config)
	else
		map("n", "<enter>", function() end, { buffer = buf })
	end
end

function M.set_colors(element, buf, size)
	-- window colors
	local hl_name = element.attrs.style.color
	a.nvim_buf_clear_namespace(buf, -1, 0, -1)
	for i = 0, size.height, 1 do
		a.nvim_buf_add_highlight(buf, -1, hl_name, i, 0, -1)
	end

	-- mark hrefs
	if element.attrs.href ~= nil then
		utils.mark_last_row(buf, size)
	end
end

function M.render(data)
	-- actual render
	local size = utils.get_width_height(data.win)
	local styled_lines = utils.lines_to_full_size(data.element.lines, size, data.element.attrs.style)
	a.nvim_buf_set_lines(data.buf, 0, -1, false, styled_lines)

	-- colors
	M.set_colors(data.element, data.buf, size)
end

function M.create_nv_element(element, parent_win, app_config, app_state)
	-- create buffer with element text
	local buf = a.nvim_create_buf(false, true)
	local win = M.create_win(element, buf, parent_win)

	-- keymaps
	M.set_keymaps(element, buf, app_state, app_config)
	local data = { element = element, win = win, buf = buf }
	return data
end

return M

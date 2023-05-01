local a = vim.api
local ts = vim.treesitter
local map = vim.keymap.set
local utils = require("htmlgui.utils")
local html_ul = require("htmlgui.html.ul")

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

function M.create_element(element, parent_win, app_config, app_state)
	-- create buffer with element text
	local buf = a.nvim_create_buf(false, true)

	-- create window
	local opts = utils.get_win_opts(element.attrs.style, parent_win)
	local win = a.nvim_open_win(buf, true, opts)

	local size = utils.get_width_height(win)
	local styled_lines = utils.lines_to_full_size(element.lines, size, element.attrs.style)
	a.nvim_buf_set_lines(buf, 0, -1, false, styled_lines)

	-- if href, then provide keymap
	if element.attrs.href ~= nil then
		map("n", "<enter>", function()
			require("htmlgui.layout").destroy(app_state)
			require("htmlgui.layout").setup(app_config, element.attrs.href)
		end, { buffer = buf })
	else
		map("n", "<enter>", function() end, { buffer = buf })
	end

	-- set color
	local hl_name = element.attrs.style.color
	a.nvim_buf_clear_namespace(buf, -1, 0, -1)
	for i = 0, size.height, 1 do
		a.nvim_buf_add_highlight(buf, -1, hl_name, i, 0, -1)
	end

	return { element = element, win = win, buf = buf }
end

return M

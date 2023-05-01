local a = vim.api
local ts = vim.treesitter
local utils = require("htmlgui.utils")

local M = {}

function M.parse_ul(div, buf)
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

	-- fancy formatting
	local cool_items = {}
	for _, line in ipairs(lines) do
		table.insert(cool_items, string.format("  🍎  %s", line))
	end

	-- put into div
	div.text = text
	div.lines = cool_items
	return div
end

return M

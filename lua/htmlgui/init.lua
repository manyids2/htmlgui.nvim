function P(x)
	print(vim.inspect(x))
end

local a = vim.api
local ts = vim.treesitter
local h = require("htmlgui.ts_html")

h.init()

local function get_rect_from_div(div)
	local parts = vim.split(div.attrs.style, ";")
	local rect = {}
	for _, v in ipairs(parts) do
		local vv = vim.split(v, ":")
		if vim.tbl_count(vv) == 2 then
			rect[vim.trim(vv[1])] = tonumber(vim.trim(vv[2]))
		end
	end
	return rect
end

local function parse_div(node, buf)
	local tag = node:child()
	local nattrs = tag:named_child_count() -- start_tag
	local attrs = {}
	for i = 1, nattrs - 1 do
		local attr = tag:named_child(i)
		local attr_key = ts.get_node_text(attr:named_child(0), buf)
		local attr_value = ts.get_node_text(attr:named_child(1):named_child(0), buf)
		attrs[attr_key] = attr_value
	end
	local text = ts.get_node_text(tag:next_named_sibling(), buf)
	return { tag = "div", attrs = attrs, text = text }
end

local function render()
  for _, s in ipairs(h.state.data) do
    a.nvim_win_close(s.win, true)
  end
  h.state.data = {}
	local body = h.get_body(h.state.html.buf)
	for i = 2, vim.tbl_count(body:named_children()) - 1 do
		local child = body:named_children()[i]
		local div = parse_div(child, h.state.html.buf)
		local rect = get_rect_from_div(div)
    table.insert(h.state.data, h.create_win(rect))
	end
end

-- Highlight on yank
local au_save = a.nvim_create_augroup("htmlgui_save", { clear = true })
a.nvim_create_autocmd("BufWritePost", {
	group = au_save,
	pattern = { "*.html" },
	callback = function()
		render()
	end,
})

local a = vim.api
local map = vim.keymap.set
local utils = require("htmlgui.utils")
local ts_css = require("htmlgui.ts_css")
local ts_html = require("htmlgui.ts_html")
local element_html = require("htmlgui.html.element")

local M = {}

local default_config = {
	layout = {
		direction = "vertical",
	},
}

function M.setup(config, filename)
	local buf
	-- return if not html file
	if filename == nil then
		buf = a.nvim_get_current_buf()
		filename = vim.fs.basename(a.nvim_buf_get_name(buf))
	end
	if not vim.endswith(filename, "html") then
		return
	end

	-- set sane defaults
	M.config = utils.validate_config(config, default_config)

	-- for navigation
	vim.cmd("e " .. filename)
	buf = a.nvim_get_current_buf()

	-- get info from html file
	M.info = M.get_html_info(buf)

	-- load script if present
	M.script = utils.load_script(M.info.script)

	if config.debug then
		M.state = M.create_bufs_wins_debug(M.info, M.config)
	else
		M.state = M.create_bufs_wins(M.info)
	end

	-- render
	M:render()
	M:set_keys()
	M:set_autoreload()
end

function M.get_html_info(buf)
	-- get info from html buffer
	local lang = "html"
	local root = utils.get_root(buf, lang)
	local title = utils.get_text_from_first_tag(ts_html.queries.title, root, buf, lang)
	local script = utils.get_text_from_first_tag(ts_html.queries.script, root, buf, lang)
	local style = utils.get_text_from_first_tag(ts_html.queries.style, root, buf, lang)
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

function M.get_css_info(buf)
	-- get info from css buffer
	local lang = "css"
	local root = utils.get_root(buf, lang)
	local filename = vim.fs.basename(a.nvim_buf_get_name(buf))
	local info = {
		root = root,
		filename = filename,
		classes = ts_css.get_classes(root, buf, lang),
	}
	return info
end

function M.create_bufs_wins(info)
	local state = { data = {} }

	-- basics
	local win = a.nvim_get_current_win()

	-- gui
	state.gui = {}
	state.gui.win = win
	state.gui.buf = a.nvim_create_buf(true, true)
	pcall(function()
		a.nvim_buf_set_name(state.gui.buf, "gui")
	end)

	-- html
	state.html = {}
	vim.cmd("e " .. info.filename)
	state.html.buf = a.nvim_get_current_buf()

	-- style
	if info.style then
		state.style = {}
		vim.cmd("e " .. info.style)
		state.style.buf = a.nvim_win_get_buf(win)
	end

	-- script
	if info.script then
		state.script = {}
		vim.cmd("e " .. info.script)
		state.script.buf = a.nvim_win_get_buf(win)
	end

	-- Focus gui buffer
	a.nvim_set_current_buf(state.gui.buf)

	return state
end

function M.create_bufs_wins_debug(info, config)
	local state = { data = {} }

	-- html
	state.html = {}
	vim.cmd("e " .. info.filename)
	state.html.win = a.nvim_get_current_win()
	state.html.buf = a.nvim_win_get_buf(state.html.win)

	-- the other split - assumes there are 2 splits
	if config.layout.direction == "vertical" then
		vim.cmd("split")
	else
		vim.cmd("vsplit")
	end

	-- gui
	state.gui = {}
	state.gui.win = a.nvim_get_current_win()
	state.gui.buf = a.nvim_create_buf(true, true)
	a.nvim_win_set_buf(state.gui.win, state.gui.buf)
	a.nvim_buf_set_name(state.gui.buf, "gui")

	-- style
	if info.style then
		if config.layout.direction == "vertical" then
			utils.focus("html", state)
			vim.cmd("vsplit " .. info.style)
		else
			utils.focus("html", state)
			vim.cmd("split " .. info.style)
		end
		state.style = {}
		state.style.win = a.nvim_get_current_win()
		state.style.buf = a.nvim_win_get_buf(state.style.win)
		vim.cmd([[wincmd =]])
	end

	-- script
	if info.script then
		if config.layout.direction == "vertical" then
			utils.focus("style", state)
			vim.cmd("vsplit " .. info.script)
		else
			utils.focus("style", state)
			vim.cmd("split " .. info.script)
		end

		state.script = {}
		state.script.win = a.nvim_get_current_win()
		state.script.buf = a.nvim_win_get_buf(state.script.win)
		vim.cmd([[wincmd =]])
	end

	return state
end

function M.statusline(win, info, debug)
	local width = a.nvim_win_get_width(win)

	local filename = info.filename
	local style = info.style
	local script = info.script

	local right = ""
	if debug then
		if filename ~= nil then
			right = string.format("❰  %s", filename)
		end
		if style ~= nil then
			right = string.format("%s ❰  %s", right, style)
		end
		if script ~= nil then
			right = string.format("%s ❰  %s", right, script)
		end
	end
	right = string.format("%s █", right)

	-- right side - files
	local title
	if debug then
		title = info.title
	else
		title = string.format(" %s", info.title)
	end
	local nright = a.nvim_strwidth(right)

	-- calc padding
	local ntitle = a.nvim_strwidth(title)
	local nuni = a.nvim_strwidth("█")
	local rem = width - ntitle - nright - nuni
	local lpad = math.ceil(rem / 2)
	local rpad = rem - lpad

	-- left - centred title
	local left = string.format("█%s%s%s", string.rep(" ", lpad), title, string.rep(" ", rpad))
	return left .. right
end

function M.render(self)
	-- reset all windows
	for _, s in ipairs(self.state.data) do
		a.nvim_win_close(s.win, true)
	end
	self.state.data = {}

	-- reload css data
	local css = { classes = {} }
	if M.state.style then
		css = M.get_css_info(M.state.style.buf)
	end

	-- TODO: for now, create elements for each direct child of body
	local body = ts_html.get_body(self.state.html.buf)
	for i = 2, vim.tbl_count(body:named_children()) - 1 do
		local child = body:named_children()[i]

		-- read and get element info from html { tag, attrs, text }
		-- NOTE: actually works for any tag with style, etc
		local element = element_html.parse_element(child, self.state.html.buf)

		-- override css styles with inline style
		element.attrs.style = ts_css.get_style_for_element(element, css)

		-- render to gui { element, win, buf }
		local data = element_html.create_element(element, self.state.gui.win, M.config, M.state)

		-- keep track
		table.insert(self.state.data, data)
	end

	local info = self.get_html_info(self.state.html.buf)
	vim.opt.statusline = M.statusline(self.state.gui.win, info, self.config.debug)
end

function M.set_keys(self)
	local elements = self.state.data
	local script = self.script
	for _, element in pairs(elements) do
		if element.element.attrs == nil then
			return
		end

		-- element = { element = .., rect = .., data = .. }
		for key, value in pairs(element.element.attrs) do
			-- get only callbacks
			if string.sub(key, 1, 3) == "on:" then
				-- wrap to insert element as data to handler
				local callback = function()
					if script ~= nil then
						if script[value] == nil then
							vim.notify("Could not set mapping: " .. value)
						end
						local handle = script[value]
						if handle ~= nil then
							handle(script, element)
						end
					end
				end

				-- apply keymap for buffer
				local lhs = string.sub(key, 4)
				map("n", lhs, callback, { buffer = element.buf })
			end
		end
	end
end

function M.set_autoreload(self)
	-- reload everythin on save for debug
	local au_save = a.nvim_create_augroup("htmlgui_save", { clear = true })
	a.nvim_create_autocmd({ "BufWritePost" }, {
		group = au_save,
		callback = function()
			self:render()
			self:set_keys()
		end,
	})

	-- Same for resize, except, keep track of current win
	local au_resize = a.nvim_create_augroup("htmlgui_resize", { clear = true })
	a.nvim_create_autocmd({ "WinResized", "VimResized" }, {
		group = au_resize,
		callback = function()
			local current_win = a.nvim_get_current_win()
			self:render()
			self:set_keys()
			if a.nvim_win_is_valid(current_win) then
				a.nvim_set_current_win(current_win)
			end
		end,
	})
end

function M.close(s)
	if s == nil then
		return
	end
	if s.buf ~= nil then
		a.nvim_buf_delete(s.buf, { force = false })
	end
	if s.win ~= nil then
		pcall(function()
			a.nvim_win_close(s.win, false)
		end)
	end
end

function M.destroy(state)
	-- remove all elements
	for _, s in ipairs(state.data) do
		a.nvim_win_close(s.win, true)
	end

	M.close(state.script)
	M.close(state.style)
	M.close(state.gui)
	M.close(state.html)
end

return M

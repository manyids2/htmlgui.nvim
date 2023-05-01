local a = vim.api
local map = vim.keymap.set
local utils = require("htmlgui.utils")
local ts_html = require("htmlgui.ts_html")
local div_html = require("htmlgui.html.div")

local M = {}

local default_config = {
	layout = {
		direction = "vertical",
	},
}

function M.setup(config)
	-- return if not html file
	local buf = a.nvim_get_current_buf()
	local filename = vim.fs.basename(a.nvim_buf_get_name(buf))
	if not vim.endswith(filename, "html") then
		return
	end

	-- set sane defaults
	config = utils.validate_config(config, default_config)

	-- create layout
	M.state = M.create_bufs_wins(config)
	M.info = ts_html.get_info(M.state.html.buf)
	M.script = utils.load_script(M.info.script)

	M:render()
	M:set_keys()
	M:set_autoreload()
end

function M.get_info(buf)
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

function M.create_bufs_wins(config)
	local state = {
		config = config,
		data = {},
	}

	local tabpage = a.nvim_get_current_tabpage()
	local win = a.nvim_tabpage_get_win(tabpage)

	-- makes sure first win is html
	state.html = {}
	state.html.win = win
	state.html.buf = a.nvim_win_get_buf(state.html.win)

	-- the other split - assumes there are 2 splits
	if config.layout.direction == "vertical" then
		vim.cmd("split")
	else
		vim.cmd("vsplit")
	end

	-- local wins = a.nvim_tabpage_list_wins(tabpage)
	state.gui = {}
	state.gui.win = a.nvim_get_current_win()
	state.gui.buf = a.nvim_create_buf(false, true)
	a.nvim_win_set_buf(state.gui.win, state.gui.buf)

	-- open rest of windows
	local info = ts_html.get_info(state.html.buf)

	-- style ( last window to use )
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

	-- script ( last window to use )
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

	return state
end

function M.status_line(win, info)
	local width = a.nvim_win_get_width(win)

  -- right side - files
	local right = string.format("❰  %s ❰  %s ❰  %s █", info.filename, info.style, info.script)
	local nright = a.nvim_strwidth(right)

  -- calc padding
	local ntitle = a.nvim_strwidth(info.title)
	local nuni = a.nvim_strwidth("█")
	local rem = width - ntitle - nright - nuni
	local lpad = math.ceil(rem / 2)
	local rpad = rem - lpad

  -- left - centred title
	local left = string.format("█%s%s%s", string.rep(" ", lpad), info.title, string.rep(" ", rpad))
	return left .. right
end

function M.render(self)
	-- reset all windows
	for _, s in ipairs(self.state.data) do
		a.nvim_win_close(s.win, true)
	end
	self.state.data = {}

	-- TODO: for now, create divs for each direct child of body
	local body = ts_html.get_body(self.state.html.buf)
	for i = 2, vim.tbl_count(body:named_children()) - 1 do
		local child = body:named_children()[i]

		-- read and get div info from html { tag, attrs, text }
		local div = div_html.parse_div(child, self.state.html.buf)

		-- render to gui { div, win, buf }
		local data = div_html.create_div(div, self.state.gui.win)

		-- keep track
		table.insert(self.state.data, data)
	end

	local info = self.get_info(self.state.html.buf)
	vim.opt.statusline = M.status_line(self.state.gui.win, info)
end

function M.set_keys(self)
	local divs = self.state.data
	local script = self.script
	for _, div in pairs(divs) do
		if div.div.attrs == nil then
			return
		end

		-- div = { div = .., rect = .., data = .. }
		for key, value in pairs(div.div.attrs) do
			-- get only callbacks
			if string.sub(key, 1, 3) == "on:" then
				-- wrap to insert div as data to handler
				local callback = function()
					local handle = script[value]
					if handle ~= nil then
						handle(script, div)
					end
				end

				-- apply keymap for buffer
				local lhs = string.sub(key, 4)
				map("n", lhs, callback, { buffer = div.buf })
			end
		end
	end
end

function M.set_autoreload(self)
	-- reload everythin on save
	local au_save = a.nvim_create_augroup("htmlgui_save", { clear = true })
	a.nvim_create_autocmd({ "BufWritePost" }, {
		group = au_save,
		callback = function()
			self:render()
			self:set_keys()
			a.nvim_set_current_win(self.state.html.win)
		end,
	})

	local au_resize = a.nvim_create_augroup("htmlgui_resize", { clear = true })
	a.nvim_create_autocmd({ "WinResized", "VimResized" }, {
		group = au_resize,
		callback = function()
			local current_win = a.nvim_get_current_win()
			self:render()
			self:set_keys()
			a.nvim_set_current_win(current_win)
		end,
	})
end

return M

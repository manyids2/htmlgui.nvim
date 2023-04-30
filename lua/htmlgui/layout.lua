local a = vim.api
local map = vim.keymap.set
local utils = require("htmlgui.utils")
local ts_html = require("htmlgui.ts_html")
local clock = os.clock

local M = {}

function M.sleep(n)
	local t0 = clock()
	while clock() - t0 <= n do
	end
end

function M.create_bufs_wins(config)
	local tabpage = a.nvim_get_current_tabpage()
	local win = a.nvim_tabpage_get_win(tabpage)

	-- makes sure first win is html
	local html = {}
	html.win = win
	html.buf = a.nvim_win_get_buf(html.win)

	if config.layout.direction == "vertical" then
		vim.cmd("split")
	else
		vim.cmd("vsplit")
	end

	-- the other split - assumes there are 2 splits
	local wins = a.nvim_tabpage_list_wins(tabpage)
	local gui = {}
	gui.win = wins[2]
	gui.buf = a.nvim_create_buf(false, true)
	a.nvim_win_set_buf(gui.win, gui.buf)

	return {
		config = config,
		html = html,
		gui = gui,
		data = {},
	}
end

function M.load_script(buf)
	-- load script file as lua module
	local scriptpath = ts_html.get_script(ts_html.get_root(buf), buf)
	scriptpath = string.sub(scriptpath, 1, string.len(scriptpath) - 4)
	if pcall(function()
		require("htmlgui." .. scriptpath)
	end) then
		local script = require("htmlgui." .. scriptpath)
		return script
	end
end

function M.status_line(win, buf)
	-- show fancy status line
	local info = ts_html.get_info(buf)
	local width = a.nvim_win_get_width(win)
	local right = string.format("❰  %s ❰  %s ❰  %s █", info.filename, info.style, info.script)
	local nright = a.nvim_strwidth(right)
	local ntitle = a.nvim_strwidth(info.title)
	local nuni = a.nvim_strwidth("█")
	local rem = width - ntitle - nright - nuni
	local lpad = math.ceil(rem / 2)
	local rpad = rem - lpad
	local left = string.format("█%s%s%s", string.rep(" ", lpad), info.title, string.rep(" ", rpad))
	return left .. right
end

function M.set_autoreload(self)
	-- reload everythin on save
	local au_save = a.nvim_create_augroup("htmlgui_save", { clear = true })
	a.nvim_create_autocmd("BufWritePost", {
		group = au_save,
		pattern = { "*.html" },
		callback = function()
			self:render()
			self:set_keys()
		end,
	})
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

function M.render(self)
	-- reset all windows
	for _, s in ipairs(self.state.data) do
		a.nvim_win_close(s.win, true)
	end
	self.state.data = {}

	-- NOTE: create divs for each direct child of body
	local body = ts_html.get_body(self.state.html.buf)
	for i = 2, vim.tbl_count(body:named_children()) - 1 do
		local child = body:named_children()[i]

		-- read and get div info from html { tag, attrs, text }
		local div = ts_html.parse_div(child, self.state.html.buf)

		-- render to gui { div, win, buf }
		local data = ts_html.create_div(div, self.state.gui.win)

		-- keep track
		table.insert(self.state.data, data)
	end

	vim.opt.statusline = M.status_line(self.state.html.win, self.state.html.buf)
end

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
	M.script = M.load_script(M.state.html.buf)

	M:render()
	M:set_keys()
	M:set_autoreload()
end

return M

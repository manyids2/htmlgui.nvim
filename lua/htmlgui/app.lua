local a = vim.api
local utils = require("htmlgui.utils")
local layout = require("htmlgui.layout")

local M = {}

local default_config = {
	debug = true,
	layout = {
		direction = "vertical",
	},
}

function M.setup(config, filename)
	-- support opening directly, and from call to setup
	if filename == nil then
		local fbuf = a.nvim_get_current_buf()
		filename = vim.fs.basename(a.nvim_buf_get_name(fbuf))
	end

	-- return if not html file
	if not vim.endswith(filename, "html") then
		return
	end

	-- set sane defaults
	M.config = utils.validate_config(config, default_config)

	-- load contents of html file to buffer
	vim.cmd("e " .. filename)
	local buf = a.nvim_get_current_buf()

	-- get title, scipt, style, etc. from html file
	M.info = layout.get_html_info(buf)

	-- attach buffers and windows to state
	M.state = layout.init_wins_bufs(M.info, M.config.layout.direction, M.config.debug)

	-- parse css, open windows
	M.state = layout.create(M)

	-- parse css, open windows
	layout.render(M)

	-- render
	layout.set_keys(M)
	layout.set_autoreload(M)
end

function M.destroy(state)
	for _, s in ipairs(state.data) do
		a.nvim_win_close(s.win, true)
	end

	layout.close(state.lua)
	layout.close(state.css)
	layout.close(state.gui)
	layout.close(state.dom)
end

return M

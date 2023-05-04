local a = vim.api
local utils = require("htmlgui.utils")
local ts_css = require("htmlgui.ts_css")
local ts_html = require("htmlgui.ts_html")
local html_element = require("htmlgui.html.element")

local M = {}

function M.get_html_info(buf)
	-- get info from html buffer
	local lang = "html"
	local root = utils.get_root(buf, lang)
	local title = utils.get_text_from_first_tag(ts_html.queries.title, root, buf, lang)
	local lua = utils.get_text_from_first_tag(ts_html.queries.lua, root, buf, lang)
	local css = utils.get_text_from_first_tag(ts_html.queries.css, root, buf, lang)
	local dom = vim.fs.basename(a.nvim_buf_get_name(buf))
	local info = {
		root = root,
		title = title,
		lua = lua,
		css = css,
		dom = dom,
	}
	return info
end

function M.load_script(scriptpath)
	-- load script file as lua module
	if scriptpath == nil then
		return
	end
	scriptpath = string.sub(scriptpath, 1, string.len(scriptpath) - 4)
	if pcall(function()
		return require(scriptpath)
	end) then
		return require(scriptpath)
	end
end

function M.get_css_info(state)
	local css = { classes = {}, html = {} }
	if state.css then
		-- get info from css buffer
		local root = utils.get_root(state.css.buf, "css")
		css = {
			root = root,
			filename = vim.fs.basename(a.nvim_buf_get_name(state.css.buf)),
			classes = ts_css.get_classes(root, state.css.buf, "css"),
			html = ts_css.get_html(root, state.css.buf, "css"),
		}
	end
	return css
end

function M.init_wins_bufs(info, direction, debug)
	local state = { data = {} }

	-- basics
	local win_cmds = {
		vertical = {
			first = "split",
			rest = "vsplit",
		},
		horizontal = {
			first = "vsplit",
			rest = "split",
		},
	}

	-- dom - same for vertical, horizontal, debug
	state.dom = {}
	vim.cmd("e " .. info.dom)
	state.dom.win = a.nvim_get_current_win()
	state.dom.buf = a.nvim_get_current_buf()

	-- gui
	if debug then
		vim.cmd(win_cmds[direction].first)
	end
	state.gui = {}
	state.gui.win = a.nvim_get_current_win()
	state.gui.buf = a.nvim_create_buf(true, true)
	a.nvim_win_set_buf(state.gui.win, state.gui.buf)
	pcall(function()
		a.nvim_buf_set_name(state.gui.buf, "gui")
	end)

	-- css
	if info.css then
		state.css = {}
		if debug then
			a.nvim_set_current_win(state.dom.win)
			vim.cmd(win_cmds[direction].rest .. " " .. info.css)
		else
			vim.cmd("e " .. info.css)
		end
		state.css.win = a.nvim_get_current_win()
		state.css.buf = a.nvim_win_get_buf(state.css.win)
	end

	-- lua
	if info.lua then
		state.lua = {}
		if debug then
			vim.cmd(win_cmds[direction].rest .. " " .. info.lua)
		else
			vim.cmd("e " .. info.lua)
		end
		state.lua.win = a.nvim_get_current_win()
		state.lua.buf = a.nvim_win_get_buf(state.lua.win)
	end

	-- Focus gui buffer
	a.nvim_set_current_win(state.gui.win)
	a.nvim_set_current_buf(state.gui.buf)

	return state
end

function M.statusline(win, info, debug)
	local width = a.nvim_win_get_width(win)

	local dom = info.dom
	local css = info.css
	local lua = info.lua

	local right = ""
	if debug then
		if dom ~= nil then
			right = string.format("❰  %s", dom)
		end
		if css ~= nil then
			right = string.format("%s ❰  %s", right, css)
		end
		if lua ~= nil then
			right = string.format("%s ❰  %s", right, lua)
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

function M.close_elements(state)
	for _, s in ipairs(state.data) do
		a.nvim_buf_delete(s.buf, { force = true })
		if a.nvim_win_is_valid(s.win) then
			a.nvim_win_close(s.win, true)
		end
	end
end

function M.parse_dom(app)
	local state = app.state
	local css = app.css
	local body = ts_html.get_body(state.dom.buf)
	for i = 2, vim.tbl_count(body:named_children()) - 1 do
		local child = body:named_children()[i]

		-- read and get element info from html { tag, attrs, text }
		local element = html_element.parse_element(child, state.dom.buf)

		-- override css styles with inline style
		element.attrs.style = ts_css.get_style_for_element(element, css)

		-- render to gui { element, win, buf }
		local parent_win = state.gui.win
		local data = html_element.create_nv_element(element, parent_win, app)

		-- keep track
		table.insert(state.data, data)
	end
end

function M.create(app)
	local state = app.state

	-- reset all windows
	M.close_elements(state)

	-- remove references to elements
	state.data = {}

	-- reload css data
	local css = M.get_css_info(state)

	-- set colorscheme
	if css.html.colorscheme ~= nil then
		vim.cmd("colorscheme " .. css.html.colorscheme)
	end

	-- set background
	if css.html.background ~= nil then
		vim.cmd("set background=" .. css.html.background)
	end

	-- TODO: for now, create elements for each direct child of body
	local body = ts_html.get_body(state.dom.buf)
	for i = 2, vim.tbl_count(body:named_children()) - 1 do
		local child = body:named_children()[i]

		-- read and get element info from html { tag, attrs, text }
		local element = html_element.parse_element(child, state.dom.buf)

		-- override css styles with inline style
		element.attrs.style = ts_css.get_style_for_element(element, css)

		-- render to gui { element, win, buf }
		local parent_win = state.gui.win
		local data = html_element.create_nv_element(element, parent_win, app)

		-- keep track
		table.insert(state.data, data)
	end
	return state
end

function M.render(app)
	local state = app.state
	local debug = app.config.debug
	for _, data in pairs(state.data) do
		html_element.render(data)
	end

	-- statusline
	local info = M.get_html_info(state.dom.buf)
	vim.opt.statusline = M.statusline(state.gui.win, info, debug)
end

function M.set_keys(app)
	local state = app.state
	local info = app.info
	local lua = M.load_script(info.lua)
	local elements = state.data

	-- remap toggle
	vim.keymap.set("n", "<C-space>", function()
		app.config.debug = not app.config.debug
		require("htmlgui.app").destroy(app.state)
		require("htmlgui.app").setup(app.config, app.info.dom)
	end, { desc = "Toggle debug console" })

	for _, data in pairs(elements) do
		if data.element.attrs == nil then
			return
		end

		-- data = { element = .., rect = .., data = .. }
		for key, value in pairs(data.element.attrs) do
			-- get only callbacks
			if vim.startswith(key, "on:") then
				-----------------CALLBACK-------------------
				-- wrap to insert element as data to handler
				local callback = function()
					if lua ~= nil then
						if lua[value] == nil then
							vim.notify("Could not find handle: " .. value)
						end

						-- get result from callback
						local returned = lua[value](lua, data.element)

						-- rerender relevant component with only state changed
						if returned ~= nil then
							for dkey, dvalue in pairs(returned) do
								data.element[dkey] = dvalue
							end
							html_element.render(data)

							-- mark visually
							utils.mark_last_row(data, " ")
						end
					end
				end
				--------------------------------------------

				-- apply keymap for buffer ( remove "on:" to get key )
				local lhs = string.sub(key, 4)
				vim.keymap.set("n", lhs, callback, { buffer = data.buf })

				-- mark visually
				utils.mark_last_row(data, " ")
			end
		end
	end
end

function M.create_render_set_keys(app)
	M.create(app)
	M.render(app)
	M.set_keys(app)
end

function M.set_autoreload(app)
	-- reload everythin on save for debug
	local au_save = a.nvim_create_augroup("htmlgui_save", { clear = true })
	a.nvim_create_autocmd({ "BufWritePost" }, {
		group = au_save,
		pattern = { "*.html", "*.css", "*.lua" },
		callback = function()
			M.create_render_set_keys(app)
		end,
	})

	local function refresh()
		local current_win = a.nvim_get_current_win()
		M.create_render_set_keys(app)
		if a.nvim_win_is_valid(current_win) then
			a.nvim_set_current_win(current_win)
		end
	end

	-- Same for resize, except, keep track of current win
	local au_resize = a.nvim_create_augroup("htmlgui_resize", { clear = true })
	a.nvim_create_autocmd({ "WinResized", "VimResized" }, {
		group = au_resize,
		pattern = { "*.html", "*.css", "*.lua" },
		callback = function()
			refresh()
		end,
	})

	-- Also for gui
	local au_resize_gui = a.nvim_create_augroup("htmlgui_resize_gui", { clear = true })
	a.nvim_create_autocmd({ "WinResized" }, {
		group = au_resize_gui,
		buffer = app.state.gui.buf,
		callback = function()
			refresh()
		end,
	})

	-- Manual refresh
	vim.keymap.set("n", "<leader>r", function()
		refresh()
	end, { desc = "Refresh" })

	-- Help
	vim.keymap.set("n", "?", function()
		P("help")
	end, { desc = "Help" })
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

return M

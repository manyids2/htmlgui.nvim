local a = vim.api
local map = vim.keymap.set
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

function M.get_css_info(buf)
	-- get info from css buffer
	local lang = "css"
	local root = utils.get_root(buf, lang)
	local filename = vim.fs.basename(a.nvim_buf_get_name(buf))
	local classes = ts_css.get_classes(root, buf, lang)
	return {
		root = root,
		filename = filename,
		classes = classes,
	}
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

function M.create(state, config)
	-- reset all windows
	for _, s in ipairs(state.data) do
		a.nvim_buf_delete(s.buf, { force = true })
		if a.nvim_win_is_valid(s.win) then
			a.nvim_win_close(s.win, true)
		end
	end
	state.data = {}

	-- reload css data
	local css = { classes = {} }
	if state.css then
		css = M.get_css_info(state.css.buf)
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
		local data = html_element.create_nv_element(element, parent_win, config, state)

		-- keep track
		table.insert(state.data, data)
	end
	return state
end

function M.render(state, debug)
	for _, data in pairs(state.data) do
		html_element.render(data)
	end

	-- statusline
	local info = M.get_html_info(state.dom.buf)
	vim.opt.statusline = M.statusline(state.gui.win, info, debug)
end

function M.set_keys(state, info)
	local lua = M.load_script(info.lua)
	local elements = state.data
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
							vim.notify("Could not set mapping: " .. value)
						end
						-- get ref to the function
						local handle = lua[value]
						if handle ~= nil then
							-- get result from callback
							local returned = handle(lua, data.element)

							-- rerender relevant component with only state changed
							if returned ~= nil then
								for dkey, dvalue in pairs(returned) do
									data.element[dkey] = dvalue
								end
								html_element.render(data)

								-- mark visually
								utils.mark_last_row(data)
							end
						end
					end
				end
				--------------------------------------------

				-- apply keymap for buffer ( remove "on:" to get key )
				local lhs = string.sub(key, 4)
				map("n", lhs, callback, { buffer = data.buf })

				-- mark visually
				utils.mark_last_row(data)
			end
		end
	end
end

function M.set_autoreload(state, config, info)
	-- reload everythin on save for debug
	local au_save = a.nvim_create_augroup("htmlgui_save", { clear = true })
	a.nvim_create_autocmd({ "BufWritePost" }, {
		group = au_save,
		callback = function()
			M.create(state, config)
			M.render(state, config.debug)
			M.set_keys(state, info)
		end,
	})

	-- Same for resize, except, keep track of current win
	local au_resize = a.nvim_create_augroup("htmlgui_resize", { clear = true })
	a.nvim_create_autocmd({ "WinResized", "VimResized" }, {
		group = au_resize,
		pattern = { "*.html", "*.css", "*.lua" },
		callback = function()
			local current_win = a.nvim_get_current_win()
			M.create(state, config)
			M.render(state, config.debug)
			M.set_keys(state, info)
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

return M

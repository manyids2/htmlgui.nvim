function P(x)
	print(vim.inspect(x))
end

local M = {}
M.state = {}

local a = vim.api
local ts = vim.treesitter
local parsers = require("nvim-treesitter.parsers")

function M.init()
	-- create a split for html, one for gui
	vim.cmd("split")
	local tabpage = a.nvim_get_current_tabpage()
	local wins = a.nvim_tabpage_list_wins(tabpage)

	local html_win = wins[1]
	local html_buf = a.nvim_win_get_buf(html_win)

	local gui_win = wins[2]
	local gui_buf = a.nvim_create_buf(false, true)
	a.nvim_win_set_buf(gui_win, gui_buf)

	local root = M.get_root(html_buf)
	M.state = {
		html = { win = html_win, buf = html_buf },
		gui = { win = gui_win, buf = gui_buf },
		root = root,
    data = {}
	}

	local filename = vim.fs.basename(a.nvim_buf_get_name(html_buf))
	local title = M.get_title(root, html_buf)
	local script = M.get_script(root, html_buf)
	local style = M.get_style(root, html_buf)
	vim.opt.statusline = M.status_line(gui_win, title, filename, script, style)
end

function M.get_root(buf)
	local parser = parsers.get_parser(buf, "html")
	local root = parser:parse()[1]:root()
	return root
end

function M.status_line(win, title, filename, script, style)
	local width = a.nvim_win_get_width(win)
	local right = string.format("❰  %s ❰  %s ❰  %s █", filename, style, script)
	local nright = a.nvim_strwidth(right)
	local ntitle = a.nvim_strwidth(title)
	local nuni = a.nvim_strwidth("█")
	local rem = width - ntitle - nright - nuni
	local lpad = math.ceil(rem / 2)
	local rpad = rem - lpad
	local left = string.format("█%s%s%s", string.rep(" ", lpad), title, string.rep(" ", rpad))
	return left .. right
end

function M.get_first_match(query, root, buf)
	local parsed_query = ts.query.parse("html", query)
	local s, _, e, _ = root:range()
	for _, node, metadata in parsed_query:iter_captures(root, buf, s, e) do
		local ids = vim.tbl_keys(metadata)
		if vim.tbl_count(ids) > 0 then
			metadata = metadata[ids[1]]
		end
		return { node = node, metadata = metadata }
	end
end

function M.get_all_matches(query, root, buf)
	local parsed_query = ts.query.parse("html", query)
	local s, _, e, _ = root:range()
	local matches = {}
	for _, node, metadata in parsed_query:iter_captures(root, buf, s, e) do
		local ids = vim.tbl_keys(metadata)
		if vim.tbl_count(ids) > 0 then
			metadata = metadata[ids[1]]
		end
		table.insert(matches, { node = node, metadata = metadata })
	end
	return matches
end

function M.get_text_from_range(range, buf)
	local text = a.nvim_buf_get_text(buf, range[1], range[2], range[3], range[4], {})[1]
	return text
end

function M.get_title(root, buf)
	local query = [[(
  element
    (start_tag (tag_name) @_head) (#eq? @_head "head")
    (element
      (start_tag (tag_name) @_title) (#eq? @_title "title")
      (text) @_text (#offset! @_text 0 0 0 0 ))
  )]]
	local tt = M.get_first_match(query, root, buf)
	return M.get_text_from_range(tt.metadata.range, buf)
end

function M.get_style(root, buf)
	local query = [[(
  element
    (start_tag (tag_name) @_head) (#eq? @_head "head")
    (element
      (self_closing_tag
        (tag_name) @_link
        (attribute
          (attribute_name) @_name
          (quoted_attribute_value (attribute_value) @_value))
  (#eq? @_link "link")
  (#eq? @_name "href")
  (#offset! @_value 0 0 0 0 )))
  )]]
	local tt = M.get_first_match(query, root, buf)
	return M.get_text_from_range(tt.metadata.range, buf)
end

function M.get_script(root, buf)
	local query = [[(
  script_element
    (start_tag
      (tag_name) @_script
      (attribute (quoted_attribute_value (attribute_value) @_value)))
  (#eq? @_script "script")
  (#offset! @_value 0 0 0 0 )
)]]
	local tt = M.get_first_match(query, root, buf)
	return M.get_text_from_range(tt.metadata.range, buf)
end

function M.get_body(buf)
	local root = M.get_root(buf)
	local query = [[(
  element
    (start_tag (tag_name) @_body)
    (#eq? @_body "body")
)]]
	local tt = M.get_first_match(query, root, buf)
	return tt.node:parent():parent()
end

function M.get_divs(root, buf)
	local query = [[(
  element
    (start_tag (tag_name) @_div)
    (#eq? @_div "div")
)]]
	local tt = M.get_all_matches(query, root, buf)
	return tt
end

function M.get_width_height()
	local stats = a.nvim_list_uis()[1]
	local width = stats.width
	local height = stats.height
	return { width = width, height = height }
end

function M.get_centre_rect(fraction)
	local size = M.get_width_height()
	local width = math.ceil(size.width * fraction)
	local height = math.ceil(size.height * fraction)
	local col = math.ceil((size.width - width) / 2)
	local row = math.ceil((size.height - height) / 2) - 1
	return { col = col, row = row, width = width, height = height }
end

function M.create_win(rect)
	local buf = a.nvim_create_buf(false, true)
	local size = M.get_width_height()
	if rect.col < 1 then
		rect.col = math.ceil(size.width * rect.col)
	end
	if rect.row < 1 then
		rect.row = math.ceil(size.height * rect.row)
	end
	if rect.height < 1 then
		rect.height = math.ceil(size.height * rect.height)
	end
	if rect.width < 1 then
		rect.width = math.ceil(size.width * rect.width)
	end

	if rect.zindex == nil then
		rect.zindex = 10
	end

	local opts = {
		relative = "editor",
		col = rect.col,
		row = rect.row,
		width = rect.width,
		height = rect.height,
		zindex = rect.zindex,
		style = "minimal",
	}
	local win = a.nvim_open_win(buf, true, opts)
	return { win = win, buf = buf }
end

return M

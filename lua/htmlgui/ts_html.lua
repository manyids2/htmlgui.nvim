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

	local parser = parsers.get_parser(html_buf, "html")
	local root = parser:parse()[1]:root()

	M.state = {
		html = { win = html_win, buf = html_buf },
		gui = { win = gui_win, buf = gui_buf },
		root = root,
	}

	local filename = vim.fs.basename(a.nvim_buf_get_name(html_buf))
	local title = M.get_title(root, html_buf)
	local script = M.get_script(root, html_buf)
	local style = M.get_style(root, html_buf)
	vim.opt.statusline = M.status_line(gui_win, title, filename, script, style)
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

function M.get_text_from_metadata(metadata, buf)
	local r = metadata.range
	local m = { sr = r[1], sc = r[2], er = r[3], ec = r[4] }
	local text = a.nvim_buf_get_text(buf, m.sr, m.sc, m.er, m.ec, {})[1]
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
	return M.get_text_from_metadata(tt.metadata, buf)
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
	return M.get_text_from_metadata(tt.metadata, buf)
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
	return M.get_text_from_metadata(tt.metadata, buf)
end

return M

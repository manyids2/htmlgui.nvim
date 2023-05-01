local a = vim.api
local ts = vim.treesitter
local parsers = require("nvim-treesitter.parsers")

local M = {}

function M.get_root(buf, lang)
	if lang == nil then
		lang = "html"
	end
	local parser = parsers.get_parser(buf, lang)
	return parser:parse()[1]:root()
end

function M.get_text_from_range(range, buf)
	-- simple trim and concat
	local lines = a.nvim_buf_get_text(buf, range[1], range[2], range[3], range[4], {})
	local text = ""
	if vim.tbl_count(lines) > 1 then
		vim.tbl_map(function(line)
			text = text .. vim.trim(line)
		end, lines)
	else
		text = lines[1]
	end
	return text
end

function M.get_info(buf)
	-- get info from html buffer
	local root = M.get_root(buf)
	local title = M.get_title(root, buf)
	local script = M.get_script(root, buf)
	local style = M.get_style(root, buf)
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

function M.get_first_match(query, root, buf, lang)
	if lang == nil then
		lang = "html"
	end
	local parsed_query = ts.query.parse(lang, query)
	local s, _, e, _ = root:range()
	for _, node, metadata in parsed_query:iter_captures(root, buf, s, e) do
		local ids = vim.tbl_keys(metadata)
		if vim.tbl_count(ids) > 0 then
			metadata = metadata[ids[1]]
		end
		return { node = node, metadata = metadata }
	end
end

function M.get_all_matches(query, root, buf, lang)
	if lang == nil then
		lang = "html"
	end
	local parsed_query = ts.query.parse(lang, query)
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
	-- HACK: unfortunately, not sure how to use treesitter here
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

return M

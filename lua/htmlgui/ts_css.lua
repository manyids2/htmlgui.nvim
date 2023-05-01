local ts = vim.treesitter
local utils = require("htmlgui.utils")

local M = {}

M.queries = {
	classes = [[(
  class_selector
    ((class_name) @_name
    (#offset! @_name 0 0 0 0 ))
  )]],
}

function M.get_classes(root, buf, lang)
	local classes = {}
	local class_matches = utils.get_matches(M.queries.classes, root, buf, lang)
	for _, class_match in pairs(class_matches) do
		-- HACK: treesitter need help
		local ruleset_children = class_match.node:parent():parent():parent():named_children()
		local text = ""
		if vim.tbl_count(ruleset_children) == 2 then
			local block = ruleset_children[2]
			text = ts.get_node_text(block, buf)
			text = string.gsub(text, "\n", "")
			text = vim.trim(string.gsub(text, "{", ""))
			text = vim.trim(string.gsub(text, "}", ""))
		end
		-- return usable things
		local data = {
			name = utils.get_text_from_range(class_match.metadata.range, buf),
			match = class_match,
			text = text,
		}
		table.insert(classes, data)
	end
	return classes
end

return M

local utils = require("htmlgui.utils")

local M = {}

M.queries = {
	title = [[(
  element
    (start_tag (tag_name) @_head) (#eq? @_head "head")
    (element
      (start_tag (tag_name) @_title) (#eq? @_title "title")
      (text) @_text (#offset! @_text 0 0 0 0 ))
  )]],
	style = [[(
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
  )]],
	script = [[(
  script_element
    (start_tag
      (tag_name) @_script
      (attribute (quoted_attribute_value (attribute_value) @_value)))
  (#eq? @_script "script")
  (#offset! @_value 0 0 0 0 )
  )]],
	body = [[(
  element
    (start_tag (tag_name) @_body)
    (#eq? @_body "body")
  )]],
	divs = [[(
  element
    (start_tag (tag_name) @_div)
    (#eq? @_div "div")
  )]],
}

function M.get_body(buf)
	local root = utils.get_root(buf, "html")
	local tt = utils.get_matches(M.queries.body, root, buf, "html")
	-- HACK: unfortunately, not sure how to use treesitter here
	return tt[1].node:parent():parent()
end

-- TODO: Use this instead of only checking children of body
function M.get_divs(buf)
	local root = utils.get_root(buf, "html")
	return utils.get_matches(M.queries.divs, root, buf)
end

return M

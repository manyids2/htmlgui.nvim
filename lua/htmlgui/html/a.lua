local map = vim.keymap.set

local M = {}

function M.set_keymaps(element, buf, app)
	local link = element.attrs.href
	if vim.startswith(link, "http://") or (vim.startswith(link, "https://")) then
		map("n", "<enter>", function()
			io.popen("$BROWSER " .. link .. " &> /dev/null")
		end, { buffer = buf })
	else
		map("n", "<enter>", function()
			require("htmlgui.app").destroy(app.state)
			require("htmlgui.app").setup(app.config, link)
		end, { buffer = buf })
	end
end

return M

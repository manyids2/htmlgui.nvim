local map = vim.keymap.set

local M = {}

function M.set_keymaps(element, buf, app_state, app_config)
	map("n", "<enter>", function()
		require("htmlgui.layout").destroy(app_state)
		require("htmlgui.layout").setup(app_config, element.attrs.href)
	end, { buffer = buf })
end

return M

local layout = require("htmlgui.layout")

function P(x)
	vim.notify(vim.inspect(x))
end

layout.setup({
  debug = true,
	layout = {
		direction = "vertical",
	},
})

local layout = require("htmlgui.layout")

function P(x)
	print(vim.inspect(x))
end

layout.setup({
  debug = false,
	layout = {
		direction = "vertical",
	},
})

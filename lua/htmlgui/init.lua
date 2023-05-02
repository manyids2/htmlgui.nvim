local app = require("htmlgui.app")

function P(x)
	vim.notify(vim.inspect(x))
end

app.setup({
  debug = true,
	layout = {
		direction = "vertical",
	},
})

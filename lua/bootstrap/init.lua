require("bootstrap.lazy")
require("bootstrap.options")
require("bootstrap.keymaps")
require("bootstrap.plugins")

function P(x)
	print(vim.inspect(x))
end

function NodeInfo(x)
	print(x:type())
end

require("bootstrap.lazy")
require("bootstrap.options")
require("bootstrap.keymaps")
require("bootstrap.plugins")

function P(x)
	print(vim.inspect(x))
end

vim.cmd([[
hi Cursor guifg=red guibg=red
hi Cursor2 guifg=red guibg=red
set guicursor=n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor
]])

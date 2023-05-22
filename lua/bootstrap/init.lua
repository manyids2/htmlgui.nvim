require("bootstrap.lazy")
require("bootstrap.options")
require("bootstrap.keymaps")
require("bootstrap.plugins")

vim.cmd([[set background=dark]])
vim.cmd([[colorscheme moonfly]])
vim.cmd([[
hi Cursor guifg=red guibg=red
hi Cursor2 guifg=red guibg=red
set guicursor=n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor
]])

function P(x)
	print(vim.inspect(x))
end

local M = {}

function M.map(mode, lhs, rhs, opts)
	opts = opts or {}
	opts.silent = opts.silent ~= false
	vim.keymap.set(mode, lhs, rhs, opts)
end

function M.set_maximize_mappings()
	M.map("n", "+", "<cmd>set wh=999<cr><cmd>set wiw=999<cr>", { desc = "Maximize window" })
	M.map("n", "=", "<cmd>set wh=10<cr><cmd>set wiw=10<cr><cmd>wincmd =<cr>", { desc = "Equalize windows" })
end

return M

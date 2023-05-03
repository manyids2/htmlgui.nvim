-- keymaps
local a = vim.api
local function map(mode, lhs, rhs, opts)
	opts = opts or {}
	opts.silent = opts.silent ~= false
	vim.keymap.set(mode, lhs, rhs, opts)
end

-- quit
map("n", "q", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<C-s>", "<cmd>w<cr>", { desc = "Save" })
map("n", "<tab>", "<cmd>wincmd w<cr>", { desc = "Next window" })
map("n", "<S-tab>", "<cmd>wincmd W<cr>", { desc = "Prev window" })
map("n", "+", "<cmd>set wh=999<cr><cmd>set wiw=999<cr>", { desc = "Maximize window" })
map("n", "=", "<cmd>set wh=10<cr><cmd>set wiw=10<cr><cmd>wincmd =<cr>", { desc = "Equalize windows" })

-- For comfort options
map("n", "<leader>l", "<cmd>:Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>c", "<cmd>:Telescope colorscheme<cr>", { desc = "Colorscheme" })

-- Dev for color
map("n", "<leader>h", "<cmd>:hi<cr>", { desc = "Highlights" })
map("n", "<leader>sh", "<cmd>:Telescope highlights<cr>", { desc = "Highlights (search)" })

-- better up/down
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Move to window
map("n", "<M-f>", "<C-w>_<C-w>|", { desc = "Maximize window" })
map("n", "<M-d>", "<C-w>=", { desc = "Equal splits" })
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Resize
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Search
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })
map({ "n", "x" }, "gw", "*N", { desc = "Search word under cursor" })
map("n", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("n", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })

-- Debug console
vim.keymap.set("n", "<C-space>", function()
	local buf = a.nvim_get_current_buf()
	local dom = vim.fs.basename(a.nvim_buf_get_name(buf))
	require("htmlgui.app").setup({ debug = false }, dom)
end, { desc = "Toggle debug console" })

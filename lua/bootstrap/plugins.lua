local plugins = {
	-- basics
	"nvim-lua/plenary.nvim",

	-- treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		run = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "lua", "html", "css" },
				auto_install = true,
			})
		end,
	},
	"nvim-treesitter/nvim-treesitter-textobjects",
	{
		"nvim-treesitter/playground",
		config = function()
			require("nvim-treesitter.configs").setup({
				playground = {
					enable = true,
					disable = {},
					updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
					persist_queries = false, -- Whether the query persists across vim sessions
					keybindings = {
						toggle_query_editor = "o",
						toggle_hl_groups = "i",
						toggle_injected_languages = "t",
						toggle_anonymous_nodes = "a",
						toggle_language_display = "I",
						focus_language = "f",
						unfocus_language = "F",
						update = "R",
						goto_node = "<cr>",
						show_help = "?",
					},
				},
			})
		end,
	},

	-- telescope
	"nvim-telescope/telescope.nvim",

	-- usability
	-- "folke/which-key.nvim",
	"folke/zen-mode.nvim",
	"stevearc/dressing.nvim",

	-- animation - cannot use cause resize is called
	{
		"echasnovski/mini.animate",
		config = function()
			require("mini.animate").setup()
		end,
	},

	-- themes
	"rktjmp/lush.nvim",
	"catppuccin/nvim",
	"bluz71/vim-moonfly-colors",
	"bluz71/vim-nightfly-colors",
	"EdenEast/nightfox.nvim",
	"nyoom-engineering/oxocarbon.nvim",
	"folke/tokyonight.nvim",
	"aktersnurra/no-clown-fiesta.nvim",
	"mcchrish/zenbones.nvim",

	-- The juice
	{ dir = "/home/x/fd/code/nvim-stuff/htmlgui.nvim" },
}

require("lazy").setup(plugins)

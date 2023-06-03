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
	"MunifTanjim/nui.nvim",
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			cmdline = {
				enabled = true, -- enables the Noice cmdline UI
				view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
				opts = {}, -- global options for the cmdline. See section on views
				format = {
					-- opts: any options passed to the view
					cmdline = { pattern = "^:", icon = "", lang = "vim" },
					search_down = false,
					search_up = false,
					filter = false,
					lua = false,
					help = false,
					input = {}, -- Used by input()
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
			},
		},
	},

	-- animation
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

	-- Debug
	{ dir = "/home/x/fd/code/nvim-stuff/htmlgui.nvim" },

	-- Release
	-- "manyids2/htmlgui.nvim",
}

require("lazy").setup(plugins)

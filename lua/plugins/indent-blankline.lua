-- indent-blankline.nvim — вертикальные линии для уровней отступов (indent guides)

return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	event = { "BufReadPost", "BufNewFile" },

	config = function()
		local ibl = require("ibl")

		ibl.setup({
			indent = {
				char = "┆", -- тонкая линия (можно "│", "┊", "┆")
				tab_char = "┆",
				highlight = {
					"Whitespace",
					"NonText",
				},
			},

			scope = {
				enabled = true, -- подсветка текущего scope
				show_start = true,
				show_end = false,
				show_exact_scope = false,

				highlight = {
					"RainbowDelimiterRed",
					"RainbowDelimiterYellow",
					"RainbowDelimiterBlue",
					"RainbowDelimiterOrange",
					"RainbowDelimiterGreen",
					"RainbowDelimiterViolet",
					"RainbowDelimiterCyan",
				},
				priority = 500,
			},

			exclude = {
				filetypes = {
					"help",
					"dashboard",
					"neo-tree",
					"lazy",
					"mason",
					"notify",
					"toggleterm",
					"Trouble",
					"terminal",
				},
				buftypes = {
					"terminal",
					"nofile",
					"quickfix",
					"prompt",
				},
			},
		})

		-- Опционально: отключить в некоторых буферах
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy", "mason" },
			callback = function()
				vim.b.indent_blankline_enabled = false
			end,
		})
	end,
}

-- Вертикальные линии для уровней отступов (indent guides)

return {
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "rebelot/kanagawa.nvim" },
		config = function()
			-- Получаем цвета из темы Kanagawa
			local colors = require("kanagawa.colors").setup()
			local theme = colors.theme

			-- Создаем кастомные группы подсветки на основе Kanagawa
			vim.api.nvim_set_hl(0, "IBLIndent", { fg = theme.ui.bg_m3 })
			vim.api.nvim_set_hl(0, "IBLScope", { fg = theme.ui.special })

			local hooks = require("ibl.hooks")

			hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
				-- Используем цвета Kanagawa для индентов
				vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E82424" })
				vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#FF9E3B" })
				vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#7E9CD8" })
				vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#FF9E3B" })
				vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98BB6C" })
				vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#957FB8" })
				vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#7FB4CA" })
			end)

			require("ibl").setup({
				indent = {
					char = "▏",
					tab_char = "▏",
					highlight = {
						"RainbowRed",
						"RainbowYellow",
						"RainbowBlue",
						"RainbowOrange",
						"RainbowGreen",
						"RainbowViolet",
						"RainbowCyan",
					},
				},
				scope = {
					enabled = true,
					show_start = false,
					show_end = false,
					char = "▎",
					highlight = "IBLScope",
				},
				exclude = {
					filetypes = {
						"help",
						"alpha",
						"dashboard",
						"neo-tree",
						"NvimTree",
						"Trouble",
						"trouble",
						"lazy",
						"mason",
						"notify",
						"toggleterm",
						"lazyterm",
						"terminal",
						"packer",
						"lspinfo",
						"TelescopePrompt",
						"TelescopeResults",
						"",
					},
					buftypes = {
						"terminal",
						"nofile",
						"quickfix",
						"prompt",
					},
				},
			})

			-- Отключаем indent-blankline для определенных буферов
			hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
			hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_tab_indent_level)
		end,
	},
}

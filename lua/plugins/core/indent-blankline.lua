-- Вертикальные линии для уровней отступов (indent guides)

return {
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "rebelot/kanagawa.nvim" },

		config = function()
			-- Простые цвета — 1 цвет для отступов, 1 для scope
			vim.api.nvim_set_hl(0, "IBLIndent", { fg = "#3b4261", nocombine = true })
			vim.api.nvim_set_hl(0, "IBLScope", { fg = "#7aa2f7", nocombine = true })

			require("ibl").setup({
				indent = {
					char = "▏",
					tab_char = "▏",
					smart_indent_cap = true, -- Автоматически скрывает отступы после текста
					highlight = "IBLIndent",
				},
				scope = {
					enabled = true,
					show_start = false, -- отключаем подсветку начала
					show_end = false, -- отключаем подсветку конца
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
					},
					buftypes = {
						"terminal",
						"nofile",
						"quickfix",
						"prompt",
					},
				},
			})
		end,
	},
}

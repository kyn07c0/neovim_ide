-- Вертикальные линии для уровней отступов (indent guides)

return {
	"lukas-reineke/indent-blankline.nvim",
	event = "VeryLazy",
	config = function()
		local ibl = require("ibl")

		-- Цвета из палитры Kanagawa
		local indent_fg = "#363646" -- sumiInk4: едва заметный на фоне #1F1F28
		local scope_fg = "#7E9CD8" -- crystalBlue: подсветка текущего контекста

		-- Настраиваем highlight-группы ДО вызова setup
		vim.api.nvim_set_hl(0, "IblIndent", { fg = indent_fg, nocombine = true })
		vim.api.nvim_set_hl(0, "IblScope", { fg = scope_fg, bold = true, nocombine = true })
		vim.api.nvim_set_hl(0, "IblWhitespace", { fg = indent_fg, nocombine = true })

		ibl.setup({
			enabled = true,
			indent = {
				char = "▏",
				highlight = "IblIndent",
			},
			scope = {
				enabled = true, -- включаем подсветку текущего контекста
				char = "▎",
				highlight = "IblScope",
				show_start = false, -- не рисуем линию на открывающей скобке
				show_end = false, -- не рисуем линию на закрывающей скобке
			},
			whitespace = {
				highlight = "IblWhitespace",
				remove_blankline_trail = true,
			},
			exclude = {
				filetypes = {
					"help",
					"startuptime",
					"neo-tree",
					"lazy",
					"mason",
					"notify",
					"noice",
					"lspinfo",
					"TelescopePrompt",
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
}

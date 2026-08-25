-- Вертикальные линии для уровней отступов (indent guides)

return {
	"lukas-reineke/indent-blankline.nvim",
	event = "VeryLazy",
	config = function()
		-- Новый API indent-blankline v3
		local ibl = require("ibl")

		-- Опционально: переопределяем символы и подсветку
		ibl.setup({
			enabled = true,
			indent = {
				char = "▏", -- символ для обычных отступов
				highlight = "IblIndent",
			},
			scope = {
				enabled = false, -- подсветка текущего контекста
				char = "|", -- символ активного контекста
				highlight = "IblScope",
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
				},
				buftypes = {
					"terminal",
					"nofile",
					"quickfix",
					"prompt",
				},
			},
		})

		-- Мягкие цвета, чтобы полосы не перекрывали каретку
		vim.api.nvim_set_hl(0, "IndentBlanklineChar", {
			fg = "#3b3b4b",
			blend = 30,
		})
		vim.api.nvim_set_hl(0, "IndentBlanklineContextChar", {
			fg = "#7aa2f7",
			bold = true,
		})

		-- Курсорная строка поверх полос (чтобы каретка была видна)
		vim.opt.cursorline = true
		vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1f1f2e" })
	end,
}

-- Тема оформления NeoVim

return {
	{
		"rebelot/kanagawa.nvim",
		priority = 1000, -- Загружается первым
		lazy = false, -- Не ленивая загрузка
		init = function()
			vim.opt.termguicolors = true
			vim.opt.background = "dark"
		end,
		config = function()
			require("kanagawa").setup({
				transparent = false,
				colors = {
					theme = {
						all = {
							ui = {
								bg_gutter = "none",
								bg = "#1F1F28",
							},
						},
					},
				},
			})
			vim.cmd("colorscheme kanagawa")
		end,
	},
}

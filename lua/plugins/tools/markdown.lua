-- Рендеринг Markdown (таблицы, заголовки, код) + Treesitter
return {
	-- Основной плагин для рендеринга
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown", "codecompanion" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"echasnovski/mini.nvim", -- Для иконок (опционально)
		},
		config = function()
			require("render-markdown").setup({
				-- Включаем рендеринг таблиц
				table = {
					enabled = true,
					-- Скрывать разделители | для чистоты
					hide_pipe_separator = false,
					-- Стиль границ таблицы
					border = {
						enabled = true,
						highlight = "RenderMarkdownTableBorder",
					},
					-- Выравнивание по колонкам
					alignment = {
						left = "left",
						center = "center",
						right = "right",
					},
				},

				-- Рендеринг заголовков
				heading = {
					enabled = true,
					icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
					width = "block",
				},

				-- Рендеринг кода
				code = {
					enabled = true,
					highlight = "RenderMarkdownCode",
					right_icon = " ",
				},

				-- Рендеринг списков
				bullet = {
					enabled = true,
					icons = { "●", "○", "◆", "◇" },
				},

				-- Рендеринг ссылок
				link = {
					enabled = true,
					image = "󰥶 ",
					email = "󰀓 ",
					hyperlink = "󰌹 ",
				},

				-- Рендеринг чекбоксов
				checkbox = {
					enabled = true,
					unchecked = "󰄱 ",
					checked = "󰱒 ",
				},

				-- Скрывать сырые символы разметки
				conceal = {
					enabled = true,
					level = 2,
				},

				-- Производительность
				performance = {
					async = true,
					defer = 50,
				},
			})

			-- Цвета для элементов таблицы (опционально)
			vim.api.nvim_set_hl(0, "RenderMarkdownTableBorder", { fg = "#6272a4" })
			vim.api.nvim_set_hl(0, "RenderMarkdownTableHead", { fg = "#8be9fd", bold = true })
			vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "#282a36" })
		end,
	},
}

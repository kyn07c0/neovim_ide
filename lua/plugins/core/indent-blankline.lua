-- Вертикальные линии для уровней отступов (indent guides)

return {
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "rebelot/kanagawa.nvim" },
		config = function()
			-- Получаем цвета из темы Kanagawa (безопасно)
			local colors_ok, colors = pcall(require, "kanagawa.colors")
			local theme = colors_ok and colors.setup().theme
				or {
					ui = { bg_m3 = "#54546d", special = "#c3ba99", fg_dim = "#7a847e" },
					syntax = { statement = "#7e9cd8" },
				}

			-- Создаем кастомные группы подсветки на основе Kanagawa
			vim.api.nvim_set_hl(0, "IBLIndent", { fg = theme.ui.bg_m3, blend = 20 })
			vim.api.nvim_set_hl(0, "IBLScope", { fg = theme.ui.special, blend = 30 })

			-- Гарантированно делает курсор видимым в режиме вставки
			vim.api.nvim_set_hl(0, "Cursor", { bg = "#7e9cd8", fg = "#1f1f28", bold = true })
			vim.api.nvim_set_hl(0, "iCursor", { bg = "#98BB6C", fg = "#1f1f28", bold = true }) -- Для режима вставки

			vim.api.nvim_create_autocmd("InsertEnter", {
				callback = function()
					vim.cmd("set guicursor=n-v-c-sm:block,i-ci-ve:ver25-iCursor,r-cr-o:hor20")
				end,
			})
			vim.api.nvim_create_autocmd("InsertLeave", {
				callback = function()
					vim.cmd("set guicursor=n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20")
				end,
			})

			local hooks = require("ibl.hooks")

			hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
				vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E82424", blend = 30 })
				vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#FF9E3B", blend = 30 })
				vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#7E9CD8", blend = 30 })
				vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#FF9E3B", blend = 30 })
				vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98BB6C", blend = 30 })
				vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#957FB8", blend = 30 })
				vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#7FB4CA", blend = 30 })
			end)

			require("ibl").setup({
				indent = {
					char = "▏",
					tab_char = "▏",
					smart_indent_cap = true, -- Автоматически скрывает отступы после текста
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

			-- Скрываем первый уровень отступа (менее интрузивно)
			hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
			hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_tab_indent_level)

			vim.api.nvim_create_autocmd("InsertEnter", {
				callback = function()
					-- Сохраняем оригинальный цвет курсора
					local orig_cursor = vim.api.nvim_get_hl(0, { name = "Cursor" })
					-- Устанавливаем контрастный цвет для режима вставки
					vim.api.nvim_set_hl(0, "Cursor", {
						bg = theme.syntax and theme.syntax.statement or "#7e9cd8",
						fg = "#1f1f28", -- Тёмный фон для контраста
						bold = true,
					})
					-- Восстанавливаем при выходе из режима вставки
					vim.api.nvim_create_autocmd("InsertLeave", {
						once = true,
						callback = function()
							vim.api.nvim_set_hl(0, "Cursor", orig_cursor)
						end,
					})
				end,
			})
		end,
	},
}

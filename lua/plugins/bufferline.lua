-- bufferline.nvim — красивые вкладки буферов сверху экрана

return {
	"akinsho/bufferline.nvim",
	version = "*", -- используем стабильную версию
	dependencies = {
		"nvim-tree/nvim-web-devicons", -- иконки (обязательно)
		"nvim-lualine/lualine.nvim", -- для интеграции с статуслайном
	},
	event = "VeryLazy",

	config = function()
		local bufferline = require("bufferline")

		bufferline.setup({
			options = {
				mode = "buffers", -- показываем буферы, а не табы
				numbers = "ordinal", -- номера буферов (1, 2, 3...)
				close_command = "bdelete! %d", -- команда закрытия
				right_mouse_command = "bdelete! %d",
				middle_mouse_command = nil,

				indicator = {
					icon = "▎", -- индикатор активного буфера
					style = "icon",
				},

				-- Настройки иконок
				buffer_close_icon = "󰅖", -- Иконка закрытия буфера
				modified_icon = "●", -- Иконка модифицированного буфера
				close_icon = "󰅙", -- Иконка закрытия таба
				left_trunc_marker = "",
				right_trunc_marker = "",

				-- Сортировка и фильтрация
				name_formatter = function(buf)
					if buf.name:match("%.md") then
						return vim.fn.fnamemodify(buf.name, ":t:r")
					end
				end,

				max_name_length = 18,
				max_prefix_length = 15,
				tab_size = 18,

				diagnostics = "nvim_lsp", -- показ ошибок/варнингов от LSP
				diagnostics_update_in_insert = false,

				diagnostics_indicator = function(count, level, diagnostics_dict, context)
					local icon = level:match("error") and " " or " "
					return " " .. icon .. count
				end,

				-- Цвета и стиль
				color_icons = true,
				show_buffer_icons = true,
				show_buffer_close_icons = true,
				show_close_icon = false,
				show_tab_indicators = true,
				persist_buffer_sort = true,

				-- Группировка (если много буферов)
				groups = {
					items = {
						require("bufferline.groups").builtin.ungrouped,
					},
				},

				-- Отключить в некоторых типах окон
				offsets = {
					{
						filetype = "neo-tree",
						text = "File Explorer",
						highlight = "Directory",
						text_align = "left",
					},
				},

				separator_style = "slant", -- или "thick", "thin", "slope"
				always_show_bufferline = true,
			},

			highlights = {
				-- Можно кастомизировать цвета под твою тему (например catppuccin)
				fill = { bg = "#1e1e2e" },
				background = { fg = "#cdd6f4", bg = "#313244" },
				buffer_selected = { fg = "#89b4fa", bg = "#45475a", bold = true },
			},
		})

		-- Горячие клавиши для переключения / закрытия
		local map = vim.keymap.set

		map("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
		map("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })

		-- Используем префикс <leader>t (tabs/buffers) вместо <leader>b
		map("n", "<leader>tn", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
		map("n", "<leader>tp", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
		map("n", "<leader>tl", "<Cmd>BufferLineCloseLeft<CR>", { desc = "Close left buffers" })
		map("n", "<leader>tr", "<Cmd>BufferLineCloseRight<CR>", { desc = "Close right buffers" })
		map("n", "<leader>tc", "<Cmd>BufferLinePickClose<CR>", { desc = "Close buffer (pick)" })
		map("n", "<leader>tp", "<Cmd>BufferLineTogglePin<CR>", { desc = "Pin / unpin buffer" })

		-- Переход к буферу по номеру (очень удобно)
		for i = 1, 9 do
			map("n", "<leader>" .. i, function()
				vim.cmd("BufferLineGoToBuffer " .. i)
			end, { desc = "Go to buffer " .. i })
		end

		-- Интеграция с which-key (добавьте в ваш which-key.lua или здесь)
		local wk = require("which-key")
		wk.add({
			{ "<leader>t", group = "tabs / buffers" },
			{ "<leader>tn", desc = "Next buffer" },
			{ "<leader>tp", desc = "Previous buffer" },
			{ "<leader>tl", desc = "Close left" },
			{ "<leader>tr", desc = "Close right" },
			{ "<leader>tc", desc = "Close picked" },
			{ "<leader>tp", desc = "Pin buffer" },
		})
	end,
}

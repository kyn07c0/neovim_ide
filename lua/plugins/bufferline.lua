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
				buffer_close_icon = "",
				modified_icon = "●",
				close_icon = "",
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
				-- fill = { bg = "#1e1e2e" },
				-- background = { fg = "#cdd6f4", bg = "#313244" },
				-- buffer_selected = { fg = "#89b4fa", bg = "#45475a", bold = true },
			},
		})

		-- Горячие клавиши для переключения / закрытия
		local map = vim.keymap.set
		map("n", "<leader>bln", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
		map("n", "<leader>blp", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Prev buffer" })
		map("n", "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", { desc = "Pin buffer" })
		map("n", "<leader>bd", "<Cmd>bdelete<CR>", { desc = "Close buffer" })
		map("n", "<leader>1", "<Cmd>BufferLineGoToBuffer 1<CR>", { desc = "Buffer 1" })
		map("n", "<leader>2", "<Cmd>BufferLineGoToBuffer 2<CR>", { desc = "Buffer 2" })
		-- ... до 9
	end,
}

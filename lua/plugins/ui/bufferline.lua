-- Вкладки буферов сверху экрана

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

		-- Единая функция закрытия для крестика, ПКМ и СКМ
		local function close_buffer(bufnum)
			local buf_info = vim.fn.getbufinfo(bufnum)[1]
			if buf_info and buf_info.changed == 1 then
				vim.notify("Буфер имеет несохраненные изменения!", vim.log.levels.WARN)
				return
			end

			-- Считаем listed-буферы, ЯВНО исключая закрываемый
			local other_listed = 0
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and buf ~= bufnum then
					other_listed = other_listed + 1
				end
			end

			-- Если есть другие буферы — просто закрываем текущий
			if other_listed > 0 then
				vim.cmd("silent! bdelete " .. bufnum)
				return
			end

			-- Это был последний буфер — закрываем Neovim
			vim.cmd("silent! bdelete " .. bufnum)
			vim.cmd("qa")
		end

		bufferline.setup({
			options = {
				mode = "buffers", -- показываем буферы, а не табы
				themable = true,
				numbers = "ordinal", -- номера буферов (1, 2, 3...)

				-- Отключаем тяжелые features
				diagnostics = false, -- отключаем для скорости
				separator_style = "thin", -- "slant" требует больше вычислений

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

				diagnostics_update_in_insert = false,

				diagnostics_indicator = function(count, level)
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

				-- Игнорируем расширения, чтобы он не появлялся в списке
				filetype_denylist = {
					"neo-tree",
					"neo-tree-popup",
					"notify",
					"noice",
					"prompt",
					"gitcommit",
					"help",
					"startuptime",
					"qf",
				},

				buftype_denylist = {
					"terminal",
					"quickfix",
					"nofile",
					"prompt",
				},

				-- Оффсеты для отображения заголовка
				offsets = {
					{
						filetype = "neo-tree",
						text = "Files",
						highlight = "Directory",
						text_align = "left",
						separator = true,
					},
				},

				always_show_bufferline = false,
				sort_by = "insert_after_current", -- быстрая сортировка

				-- Клавиши для закрытия
				close_command = close_buffer,

				-- Правая клавиша мыши для закрытия
				right_mouse_command = close_buffer,

				-- Клавиша средней кнопки мыши для закрытия
				middle_mouse_command = close_buffer,
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
	end,
}

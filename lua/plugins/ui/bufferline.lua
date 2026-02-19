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
				close_command = function(bufnum)
					local buf_info = vim.fn.getbufinfo(bufnum)[1]
					if buf_info and buf_info.changed == 1 then
						vim.notify(
							"Буфер имеет несохраненные изменения!",
							vim.log.levels.WARN
						)
						return
					end

					-- Получаем все listed буферы ДО закрытия
					local listed_buffers = {}
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
							table.insert(listed_buffers, buf)
						end
					end

					-- Если закрывается НЕ последний буфер — просто закрываем
					if #listed_buffers > 1 then
						vim.cmd("silent! bdelete " .. bufnum)
						vim.cmd("BufferLineCycleNext")
						return
					end

					-- Если это ПОСЛЕДНИЙ буфер:
					-- 1. Не удаляем его, а очищаем и делаем unlisted
					vim.cmd("silent! bdelete " .. bufnum)

					-- 2. Создаём новый пустой буфер и делаем его unlisted
					local new_buf = vim.api.nvim_create_buf(false, true) -- no file, scratch
					vim.api.nvim_set_current_buf(new_buf)
					vim.bo[new_buf].buflisted = false
					vim.bo[new_buf].buftype = "nofile"
					vim.bo[new_buf].swapfile = false
					vim.bo[new_buf].modifiable = false

					-- 3. Показываем neo-tree
					vim.cmd("Neotree show")

					-- 4. Фокус на neo-tree
					vim.defer_fn(function()
						-- Найти окно neo-tree и перейти в него
						for _, win in ipairs(vim.api.nvim_list_wins()) do
							local buf = vim.api.nvim_win_get_buf(win)
							if vim.bo[buf].filetype == "neo-tree" then
								vim.api.nvim_set_current_win(win)
								break
							end
						end
					end, 50)
				end,

				-- Правая клавиша мыши для закрытия
				right_mouse_command = function(bufnum)
					require("bufferline").close_command(bufnum)
				end,

				-- Клавиша средней кнопки мыши для закрытия
				middle_mouse_command = function(bufnum)
					require("bufferline").close_command(bufnum)
				end,
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

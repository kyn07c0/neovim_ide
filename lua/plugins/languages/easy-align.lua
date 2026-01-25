-- Выравнивание текста

return {
	"junegunn/vim-easy-align",
	event = { "CursorHold", "CursorHoldI" }, -- Загружать при удержании курсора

	init = function()
		-- Основная горячая клавиша
		vim.keymap.set({ "n", "x" }, "ga", "<Plug>(EasyAlign)", {
			desc = "EasyAlign (визуальный режим для блока)",
		})

		-- Быстрые выравнивания по часто используемым символам
		local align_mappings = {
			{ "=", "Align by =" },
			{ ":", "Align by :" },
			{ ",", "Align by ," },
			{ "|", "Align by |" },
			{ ".", "Align by ." },
			{ ";", "Align by ;" },
			{ "&", "Align by &" },
			{ "=>", "Align by =>" },
			{ "->", "Align by ->" },
			{ "<-", "Align by <-" },
			{ "#", "Align by #" },
			{ "/", "Align by // комментарии" },
			{ "*", "Align by * указатели" },
			{ "{", "Align by {" },
			{ "}", "Align by }" },
			{ "(", "Align by (" },
			{ ")", "Align by )" },
			{ "[", "Align by [" },
			{ "]", "Align by ]" },
			{ "<", "Align by <" },
			{ ">", "Align by >" },
		}

		for _, mapping in ipairs(align_mappings) do
			local key, desc = mapping[1], mapping[2]
			vim.keymap.set("n", "g" .. key, function()
				vim.cmd("EasyAlign " .. key)
			end, { desc = desc })
		end

		-- Выравнивание по регулярным выражениям
		--		vim.keymap.set("n", "g\\", function()
		--			local pattern = vim.fn.input("Pattern to align by: ")
		--			if pattern ~= "" then
		--				vim.cmd("EasyAlign " .. pattern)
		--			end
		--		end, { desc = "Align by custom pattern" })
	end,

	config = function()
		-- Настройки easy-align
		vim.g.easy_align_ignore_groups = { "Comment", "String" }
		vim.g.easy_align_ignore_unmatched = 1
		vim.g.easy_align_delimiters = {
			-- Кастомные разделители
			["="] = {
				pattern = "=",
				left_margin = 1,
				right_margin = 1,
				stick_to_left = 0,
			},
			[":"] = {
				pattern = ":",
				left_margin = 0,
				right_margin = 1,
				stick_to_left = 1,
			},
			[","] = {
				pattern = ",",
				left_margin = 0,
				right_margin = 1,
				stick_to_left = 1,
			},
			["|"] = {
				pattern = "|\\|\\|",
				left_margin = 1,
				right_margin = 1,
				stick_to_left = 0,
			},
			["#"] = {
				pattern = "#",
				ignore_groups = { "String" },
				delimiter_align = "l",
			},
			["/"] = {
				pattern = "//\\|/\\*\\|\\*/",
				delimiter_align = "l",
				ignore_groups = { "String" },
			},
			-- Для C/C++ указателей
			["*"] = {
				pattern = "\\*",
				left_margin = 0,
				right_margin = 1,
				stick_to_left = 0,
			},
			-- Для C++ лямбд
			["->"] = {
				pattern = "->",
				left_margin = 1,
				right_margin = 1,
			},
			-- Для JS/TS стрелочных функций
			["=>"] = {
				pattern = "=>",
				left_margin = 1,
				right_margin = 1,
			},
		}

		-- Настройки для разных файлов
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "cpp", "c", "java", "javascript", "typescript" },
			callback = function()
				-- Автоматическое выравнивание по = для инициализаций
				vim.keymap.set("n", "<leader>a=", "vip:EasyAlign =<CR>", {
					buffer = true,
					desc = "Align paragraph by =",
				})
			end,
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "markdown", "text" },
			callback = function()
				-- Для markdown таблиц
				vim.keymap.set("n", "<leader>a|", "vip:EasyAlign |<CR>", {
					buffer = true,
					desc = "Align markdown table",
				})
			end,
		})
	end,
}

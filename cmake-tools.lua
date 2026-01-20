-- cmake-tools.nvim — удобная интеграция с CMake (build, run, debug)

return {
	"civitasv/cmake-tools.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	ft = { "cmake", "cpp", "c" }, -- загружаем для CMake-файлов

	config = function()
		local cmake = require("cmake-tools")

		cmake.setup({
			cmake_command = "cmake",
			cmake_build_directory = "build", -- папка для сборки
			cmake_generate_options = {
				"-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
				"-DCMAKE_BUILD_TYPE=Debug",
			},

			-- Окно консоли
			cmake_console_size = 15, -- размер консоли снизу
			cmake_show_console = "always", -- всегда показывать консоль
			cmake_close_console_on_success = false, -- не закрывать при успехе
			cmake_close_console_on_failure = false, -- не закрывать при ошибке
			cmake_console_position = "below", -- позиция окна
			cmake_console_floating = false, -- не плавающее окно
			cmake_console_interval = 50, -- интервал обновления вывода
			cmake_build_options = { "--verbose" }, -- подробный вывод
			cmake_console_height = 15, -- явная высота
			cmake_console_title = "CMake Console", -- заголовок окна

			-- Интеграция с dap
			cmake_dap_configuration = {
				name = "cpp",
				type = "codelldb",
				request = "launch",
				stopOnEntry = false,
				runInTerminal = true,
			},

			-- Дополнительные настройки для надежности
			cmake_variants_message = {
				short = { show = true },
				long = { show = true, max_length = 40 },
			},
		})

		-- Функция для принудительного открытия/показа консоли ПЕРЕД действием
		local function ensure_console_open_and_execute(action_func, action_name)
			-- Сначала открываем/активируем консоль
			local console_found = false

			-- Ищем существующую консоль
			for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
				local bufname = vim.api.nvim_buf_get_name(bufnr)
				if bufname:match("CMake Console") then
					console_found = true
					local winid = vim.fn.bufwinid(bufnr)
					if winid ~= -1 then
						vim.api.nvim_set_current_win(winid)
						-- Прокручиваем вниз
						vim.api.nvim_buf_call(bufnr, function()
							vim.cmd("normal! G")
						end)
					end
					break
				end
			end

			-- Если консоль не найдена, создаем через cmake-tools
			if not console_found then
				-- Используем встроенную команду для открытия консоли
				vim.cmd("CMakeOpen")

				-- Ждем создания консоли
				vim.defer_fn(function()
					for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
						local bufname = vim.api.nvim_buf_get_name(bufnr)
						if bufname:match("CMake Console") then
							local winid = vim.fn.bufwinid(bufnr)
							if winid ~= -1 then
								vim.api.nvim_set_current_win(winid)
								-- Добавляем заголовок
								vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, {
									"╔════════════════════════════════════════╗",
									"║        CMake Build Console            ║",
									"╚════════════════════════════════════════╝",
									"",
								})
							end
							break
						end
					end
				end, 300)
			end

			-- Ждем и выполняем действие
			vim.defer_fn(function()
				action_func()
				vim.notify(action_name, vim.log.levels.INFO)
			end, 500)
		end

		-- Горячие клавиши с гарантированным открытием консоли
		vim.keymap.set("n", "<leader>cg", function()
			ensure_console_open_and_execute(function()
				cmake.generate({})
			end, "Генерация CMake...")
		end, { desc = "CMake Generate" })

		vim.keymap.set("n", "<leader>cb", function()
			ensure_console_open_and_execute(function()
				cmake.build({})
			end, "Сборка проекта...")
		end, { desc = "CMake Build" })

		vim.keymap.set("n", "<leader>cr", function()
			ensure_console_open_and_execute(function()
				cmake.run({})
			end, "Запуск проекта...")
		end, { desc = "CMake Run" })

		-- Другие команды без консоли
		vim.keymap.set("n", "<leader>cd", "<cmd>CMakeDebug<cr>", { desc = "CMake Debug" })
		vim.keymap.set("n", "<leader>cc", "<cmd>CMakeClean<cr>", { desc = "CMake Clean" })
		vim.keymap.set("n", "<leader>ct", "<cmd>CMakeSelectTarget<cr>", { desc = "Select Target" })
		vim.keymap.set("n", "<leader>co", "<cmd>CMakeOpen<cr>", { desc = "Open CMake console" })
		vim.keymap.set("n", "<leader>cx", "<cmd>CMakeClose<cr>", { desc = "Close CMake console" })

		-- Автоматически обновлять compile_commands.json
		vim.api.nvim_create_autocmd("User", {
			pattern = "CMakeBuildFinished",
			callback = function()
				local root = vim.fn.getcwd()
				local source = root .. "/build/compile_commands.json"
				local target = root .. "/compile_commands.json"

				if vim.fn.filereadable(source) == 1 then
					os.execute("cp " .. source .. " " .. target)
					vim.notify("compile_commands.json обновлен", vim.log.levels.INFO)
				end

				-- Добавляем сообщение в консоль после сборки
				vim.defer_fn(function()
					for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
						local bufname = vim.api.nvim_buf_get_name(bufnr)
						if bufname:match("CMake Console") then
							local winid = vim.fn.bufwinid(bufnr)
							if winid ~= -1 then
								-- Переходим в окно консоли
								vim.api.nvim_set_current_win(winid)
								-- Прокручиваем вниз
								vim.api.nvim_buf_call(bufnr, function()
									vim.cmd("normal! G")
								end)
								-- Добавляем финальное сообщение
								vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
									"",
									"══════════════════════════════════════════",
									"✅ Сборка завершена успешно!",
									"Окно останется открытым",
									"══════════════════════════════════════════",
									"",
								})
								-- Возвращаемся в предыдущее окно
								vim.cmd("wincmd p")
							end
							break
						end
					end
				end, 1000) -- Ждем дольше для гарантии
			end,
		})

		-- Дополнительно: Хук после открытия консоли
		vim.api.nvim_create_autocmd("User", {
			pattern = "CMakeConsoleOpened",
			callback = function()
				vim.defer_fn(function()
					for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
						local bufname = vim.api.nvim_buf_get_name(bufnr)
						if bufname:match("CMake Console") then
							-- Устанавливаем, что буфер не должен закрываться
							vim.bo[bufnr].bufhidden = ""
							vim.bo[bufnr].buflisted = true
							break
						end
					end
				end, 200)
			end,
		})
	end,
}

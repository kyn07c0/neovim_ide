-- Интеграция с CMake (build, run, debug)

return {
	"civitasv/cmake-tools.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"mfussenegger/nvim-dap",
	},
	ft = { "cmake", "cpp", "c" }, -- загружаем для CMake-файлов

	config = function()
		local cmake = require("cmake-tools")
		local M = {}
		M.runner_args = {} -- Хранилище для аргументов

		-- Глобальные переменные для общего терминала
		local shared_terminal_bufnr = nil
		local shared_terminal_winid = nil
		M.run_terminal_bufnr = nil -- ID буфера терминала для запуска (для обратной совместимости)
		M.run_terminal_winid = nil -- ID окна терминала для запуска (для обратной совместимости)

		-- Настраиваем плагин так, чтобы он не создавал свои терминалы
		cmake.setup({
			cmake_command = "cmake",
			cmake_build_directory = "build", -- папка для сборки
			cmake_generate_options = {
				"-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
				"-DCMAKE_BUILD_TYPE=Debug",
			},

			-- Настройки для аргументов запуска
			cmake_runner_args = {
				default_args = {},
				by_target = {},
			},

			-- Окно консоли для сборки и генерации
			cmake_console_size = 20, -- размер консоли снизу
			cmake_show_console = "always", -- всегда показывать консоль
			cmake_close_console_on_success = false, -- не закрывать при успехе
			cmake_close_console_on_failure = false, -- не закрывать при ошибке
			cmake_console_position = "below", -- позиция окна
			cmake_console_floating = false, -- не плавающее окно
			cmake_console_interval = 50, -- интервал обновления вывода
			cmake_build_options = { "--verbose" }, -- подробный вывод
			cmake_console_height = 20, -- явная высота
			cmake_console_title = "CMake Console", -- заголовок окна
			cmake_console_autoscroll = true, -- автоматическая прокрутка

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

			-- Отключаем встроенный запуск программ
			cmake_runner = {
				run = false, -- Не использовать встроенный runner
			},
		})

		-- Создаем единый буфер для всех логов
		local function get_shared_log_buffer()
			-- Ищем уже существующий буфер лога
			for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_valid(bufnr) then
					local bufname = vim.api.nvim_buf_get_name(bufnr)
					-- Ищем по имени
					if bufname:match("^CMake Shared Log") then
						return bufnr
					end
				end
			end

			-- Если не нашли, создаем новый буфер
			local bufnr = vim.api.nvim_create_buf(true, false)

			-- Устанавливаем уникальное имя с временной меткой
			local timestamp = os.date("%Y%m%d_%H%M%S")
			local bufname = "CMake Shared Log " .. timestamp

			vim.api.nvim_buf_set_name(bufnr, bufname)
			vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
			vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })
			vim.api.nvim_set_option_value("filetype", "log", { buf = bufnr })
			vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
			vim.api.nvim_set_option_value("readonly", false, { buf = bufnr })

			-- Добавляем заголовок
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
				"╔══════════════════════════════════════════╗",
				"║           CMake Shared Log               ║",
				"║     Все операции в одном окне            ║",
				"╚══════════════════════════════════════════╝",
				"",
				"Создан: " .. os.date("%H:%M:%S"),
				"",
			})

			-- Возвращаем режим только для чтения
			vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
			vim.api.nvim_set_option_value("readonly", true, { buf = bufnr })

			return bufnr
		end

		-- Функция для добавления сообщения в общий лог
		local function add_to_shared_log(message, is_error)
			-- Получаем или создаем буфер
			local bufnr = get_shared_log_buffer()

			if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
				-- Если не удалось получить буфер, просто показываем уведомление
				if is_error then
					vim.notify("ОШИБКА: " .. message, vim.log.levels.ERROR)
				else
					vim.notify(message, vim.log.levels.INFO)
				end
				return
			end

			local timestamp = os.date("%H:%M:%S")
			local lines = vim.split(message, "\n")

			-- Безопасно добавляем сообщение
			local success = pcall(function()
				-- Временно включаем редактирование
				vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
				vim.api.nvim_set_option_value("readonly", false, { buf = bufnr })

				-- Добавляем разделитель если есть предыдущие сообщения
				local line_count = vim.api.nvim_buf_line_count(bufnr)
				if line_count > 8 then -- Учитываем заголовочные строки
					vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
						"────────────────────────────────────────────",
					})
				end

				-- Добавляем основное сообщение
				vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
					"[" .. timestamp .. "] " .. (is_error and "❌ " or "✅ ") .. lines[1],
				})

				-- Добавляем дополнительные строки
				if #lines > 1 then
					for i = 2, #lines do
						vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
							"        " .. lines[i],
						})
					end
				end

				-- Прокручиваем вниз в окне если оно открыто
				for _, winid in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_get_buf(winid) == bufnr then
						vim.api.nvim_win_call(winid, function()
							vim.cmd("normal! G")
						end)
						break
					end
				end

				-- Возвращаем режим только для чтения
				vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
				vim.api.nvim_set_option_value("readonly", true, { buf = bufnr })
			end)

			if not success then
				-- Если произошла ошибка при записи в буфер, показываем уведомление
				if is_error then
					vim.notify("ОШИБКА записи в лог: " .. message, vim.log.levels.ERROR)
				else
					vim.notify("Инфо: " .. message, vim.log.levels.INFO)
				end
			end
		end

		-- Функция для поиска исполняемого файла
		local function find_executable(target)
			local possible_paths = {
				"./build/" .. target,
				"./build/Debug/" .. target,
				"./build/Release/" .. target,
				"./build/bin/" .. target,
				"./build/Debug/bin/" .. target,
				"./build/Release/bin/" .. target,
				target, -- Возможно уже полный путь
			}

			for _, path in ipairs(possible_paths) do
				if vim.fn.executable(path) == 1 then
					return path
				end
				-- Проверяем существование файла (не обязательно исполняемого для Windows)
				if vim.fn.filereadable(path) == 1 then
					return path
				end
			end

			-- Если не нашли, используем find
			local handle = io.popen("find build -name '" .. target .. "' -type f 2>/dev/null | head -1")
			if handle then
				local found = handle:read("*a"):gsub("%s+$", "")
				handle:close()
				if found ~= "" then
					return found
				end
			end

			return nil
		end

		-- Функция для поиска существующего окна общего терминала
		local function find_shared_terminal_window()
			-- Сначала проверяем наш сохраненный терминал
			if shared_terminal_winid and vim.api.nvim_win_is_valid(shared_terminal_winid) then
				local bufnr = vim.api.nvim_win_get_buf(shared_terminal_winid)
				local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
				if buftype == "terminal" then
					return shared_terminal_winid, bufnr
				end
			end

			-- Проверяем сохраненный ID окна из M (для обратной совместимости)
			if M.run_terminal_winid and vim.api.nvim_win_is_valid(M.run_terminal_winid) then
				local bufnr = vim.api.nvim_win_get_buf(M.run_terminal_winid)
				local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
				if buftype == "terminal" then
					-- Обновляем наши глобальные переменные
					shared_terminal_winid = M.run_terminal_winid
					shared_terminal_bufnr = M.run_terminal_bufnr
					return shared_terminal_winid, bufnr
				end
			end

			-- Ищем среди всех окон
			for _, winid in ipairs(vim.api.nvim_list_wins()) do
				local bufnr = vim.api.nvim_win_get_buf(winid)
				local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })

				if buftype == "terminal" then
					-- Проверяем, не является ли это окном консоли CMake
					local bufname = vim.api.nvim_buf_get_name(bufnr)
					if not bufname:match("cmake_tools") then
						-- Сохраняем найденное окно
						shared_terminal_winid = winid
						shared_terminal_bufnr = bufnr
						M.run_terminal_winid = winid
						M.run_terminal_bufnr = bufnr
						return winid, bufnr
					end
				end
			end

			return nil, nil
		end

		-- Функция для закрытия общего терминала
		local function close_shared_terminal()
			local winid, bufnr = find_shared_terminal_window()
			if winid then
				-- Используем vim.schedule для асинхронного закрытия
				vim.schedule(function()
					if vim.api.nvim_win_is_valid(winid) then
						-- Останавливаем процесс в терминале
						local job_id = bufnr and vim.api.nvim_buf_get_var(bufnr, "terminal_job_id")
						if job_id then
							pcall(vim.fn.chansend, job_id, "\003") -- Ctrl+C
							vim.fn.wait(100, function() end)
						end

						-- Закрываем окно
						vim.api.nvim_win_close(winid, true)
					end

					-- Закрываем буфер
					if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
						vim.api.nvim_buf_delete(bufnr, { force = true })
					end

					-- Очищаем все переменные
					shared_terminal_winid = nil
					shared_terminal_bufnr = nil
					M.run_terminal_winid = nil
					M.run_terminal_bufnr = nil
				end)
			end
		end

		-- Функция для запуска программы в общем терминале
		local function run_in_shared_terminal(cmd, target, args)
			-- Закрываем старый терминал если он есть
			close_shared_terminal()

			-- Ждем завершения закрытия окон
			vim.fn.wait(300, function() end)

			-- Проверяем, что нет операций закрытия окон
			local safe_to_proceed = true
			for i = 1, 10 do -- Проверяем несколько раз
				local windows = vim.api.nvim_list_wins()
				for _, winid in ipairs(windows) do
					if not vim.api.nvim_win_is_valid(winid) then
						safe_to_proceed = false
						break
					end
				end
				if not safe_to_proceed then
					vim.fn.wait(50, function() end)
				else
					break
				end
			end

			if not safe_to_proceed then
				vim.notify(
					"Не удалось создать терминал: система окон занята",
					vim.log.levels.ERROR
				)
				return
			end

			-- Сохраняем текущее окно перед любыми операциями
			local current_win = vim.api.nvim_get_current_win()
			-- Проверяем, что окно все еще валидно
			if not vim.api.nvim_win_is_valid(current_win) then
				current_win = -1
				for _, winid in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_is_valid(winid) then
						current_win = winid
						break
					end
				end
			end

			if current_win == -1 then
				vim.notify("Нет доступных окон", vim.log.levels.ERROR)
				return
			end

			-- Устанавливаем текущее окно
			vim.api.nvim_set_current_win(current_win)

			-- Ждем еще немного
			vim.fn.wait(100, function() end)

			-- Используем асинхронное создание терминала через vim.schedule
			vim.schedule(function()
				-- Еще одна проверка
				if not vim.api.nvim_win_is_valid(current_win) then
					vim.notify(
						"Окно стало невалидным во время создания терминала",
						vim.log.levels.ERROR
					)
					return
				end

				-- Создаем новое окно терминала
				vim.cmd("split")
				vim.fn.wait(50, function() end)
				vim.cmd("terminal " .. cmd)
				vim.cmd("startinsert")

				-- Сохраняем ID окна и буфера
				shared_terminal_winid = vim.api.nvim_get_current_win()
				shared_terminal_bufnr = vim.api.nvim_get_current_buf()
				M.run_terminal_winid = shared_terminal_winid
				M.run_terminal_bufnr = shared_terminal_bufnr

				-- Устанавливаем размер окна
				vim.api.nvim_win_set_height(shared_terminal_winid, 20)

				-- Добавляем заголовок окна
				local winbar_text = "▶ " .. target
				if args and args ~= "" then
					winbar_text = winbar_text .. " " .. args
				end
				vim.api.nvim_set_option_value("winbar", winbar_text, { win = shared_terminal_winid })

				-- Автоматическое удаление при закрытии окна
				vim.api.nvim_create_autocmd("WinClosed", {
					buffer = shared_terminal_bufnr,
					once = true,
					callback = function()
						shared_terminal_winid = nil
						shared_terminal_bufnr = nil
						M.run_terminal_winid = nil
						M.run_terminal_bufnr = nil
					end,
				})

				-- Возвращаем фокус в предыдущее окно
				if vim.api.nvim_win_is_valid(current_win) then
					vim.api.nvim_set_current_win(current_win)
				end
			end)

			return shared_terminal_winid, shared_terminal_bufnr
		end

		-- Горячие клавиши с общим логом
		vim.keymap.set("n", "<leader>cg", function()
			add_to_shared_log("Генерация CMake...", false)
			local success, result = pcall(cmake.generate, {})
			if success then
				add_to_shared_log("Генерация CMake завершена", false)
				vim.notify("Генерация CMake завершена", vim.log.levels.INFO)
			else
				add_to_shared_log("Ошибка генерации CMake: " .. tostring(result), true)
				vim.notify("Ошибка генерации CMake", vim.log.levels.ERROR)
			end
		end, { desc = "CMake Generate" })

		vim.keymap.set("n", "<leader>cb", function()
			add_to_shared_log("Сборка проекта...", false)
			local success, result = pcall(cmake.build, {})
			if success then
				add_to_shared_log("Сборка проекта завершена", false)
				vim.notify("Сборка проекта завершена", vim.log.levels.INFO)
			else
				add_to_shared_log("Ошибка сборки проекта: " .. tostring(result), true)
				vim.notify("Ошибка сборки проекта", vim.log.levels.ERROR)
			end
		end, { desc = "CMake Build" })

		-- Запуск без аргументов (использует общий терминал)
		vim.keymap.set("n", "<leader>cr", function()
			-- Получаем текущую цель
			local target = nil
			local status_ok, result = pcall(function()
				return cmake.get_launch_target()
			end)

			if status_ok and result then
				target = result
			end

			if not target or target == "" then
				-- Если не можем получить цель, запросим у пользователя
				target = vim.fn.input("Имя исполняемого файла (из build/): ", "")
				if target == "" then
					vim.notify("Цель не указана", vim.log.levels.WARN)
					return
				end
			end

			-- Ищем исполняемый файл
			local exe_path = find_executable(target)
			if not exe_path then
				vim.notify("Исполняемый файл не найден: " .. target, vim.log.levels.ERROR)
				add_to_shared_log("ОШИБКА: Исполняемый файл не найден: " .. target, true)
				return
			end

			-- Строим команду для запуска
			local cmd = exe_path

			add_to_shared_log("Запуск программы: " .. cmd, false)

			-- Запускаем в общем терминале
			run_in_shared_terminal(cmd, target, nil)

			vim.notify("Запущено: " .. target, vim.log.levels.INFO)
		end, { desc = "CMake Run" })

		-- Запуск с аргументами (использует тот же общий терминал)
		vim.keymap.set("n", "<leader>cR", function()
			-- Получаем текущую цель
			local target = nil
			local status_ok, result = pcall(function()
				return cmake.get_launch_target()
			end)

			if status_ok and result then
				target = result
			end

			if not target or target == "" then
				-- Если не можем получить цель, запросим у пользователя
				target = vim.fn.input("Имя исполняемого файла (из build/): ", "")
				if target == "" then
					vim.notify("Цель не указана", vim.log.levels.WARN)
					return
				end
			end

			-- Запрашиваем аргументы (используем сохраненные если есть)
			local last_args = M.runner_args[target] or ""
			local args_input = vim.fn.input("Аргументы для " .. target .. ": ", last_args)

			-- Сохраняем аргументы
			if args_input ~= "" then
				M.runner_args[target] = args_input
			end

			-- Ищем исполняемый файл
			local exe_path = find_executable(target)
			if not exe_path then
				vim.notify("Исполняемый файл не найден: " .. target, vim.log.levels.ERROR)
				add_to_shared_log("ОШИБКА: Исполняемый файл не найден: " .. target, true)
				return
			end

			-- Строим команду для запуска
			local cmd = exe_path
			if args_input ~= "" then
				cmd = cmd .. " " .. args_input
			end

			add_to_shared_log("Запуск программы: " .. cmd, false)

			-- Запускаем в общем терминале
			run_in_shared_terminal(cmd, target, args_input)

			vim.notify(
				"Запущено: " .. target .. (args_input ~= "" and " с аргументами" or ""),
				vim.log.levels.INFO
			)
		end, { desc = "CMake Run with args" })

		-- Закрытие терминала
		vim.keymap.set("n", "<leader>cz", function()
			close_shared_terminal()
			vim.notify("Терминал запуска закрыт", vim.log.levels.INFO)
		end, { desc = "Close run terminal" })

		-- Выбор цели
		vim.keymap.set("n", "<leader>ct", "<cmd>CMakeSelectTarget<cr>", { desc = "Select Target" })

		-- Просмотр сохраненных аргументов
		vim.keymap.set("n", "<leader>ca", function()
			local has_args = false
			local msg = "Сохраненные аргументы:\n"

			for target, args in pairs(M.runner_args) do
				if args ~= "" then
					has_args = true
					msg = msg .. "  " .. target .. ": " .. args .. "\n"
				end
			end

			if has_args then
				vim.notify(msg, vim.log.levels.INFO)
			else
				vim.notify("Нет сохраненных аргументов", vim.log.levels.INFO)
			end
		end, { desc = "Show saved args" })

		-- Сохранение аргументов в файл проекта
		vim.keymap.set("n", "<leader>cs", function()
			local config_file = vim.fn.getcwd() .. "/.cmake-runner-args"
			local lines = {}

			for target, args in pairs(M.runner_args) do
				if args ~= "" then
					table.insert(lines, target .. ":" .. args)
				end
			end

			if #lines > 0 then
				vim.fn.writefile(lines, config_file)
				vim.notify("Аргументы сохранены в " .. config_file, vim.log.levels.INFO)
			else
				vim.notify("Нет аргументов для сохранения", vim.log.levels.WARN)
			end
		end, { desc = "Save args to file" })

		-- Автозагрузка аргументов из файла
		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				local config_file = vim.fn.getcwd() .. "/.cmake-runner-args"
				if vim.fn.filereadable(config_file) == 1 then
					local lines = vim.fn.readfile(config_file)

					for _, line in ipairs(lines) do
						local target, args = string.match(line, "([^:]+):(.+)")
						if target and args then
							M.runner_args[target] = args
						end
					end

					vim.notify("Загружены сохраненные аргументы", vim.log.levels.INFO)
				end
			end,
		})

		-- Другие команды
		vim.keymap.set("n", "<leader>cd", "<cmd>CMakeDebug<cr>", { desc = "CMake Debug" })
		vim.keymap.set("n", "<leader>cc", "<cmd>CMakeClean<cr>", { desc = "CMake Clean" })

		-- Управление общим логом
		vim.keymap.set("n", "<leader>co", function()
			-- Создаем или получаем буфер лога
			local bufnr = get_shared_log_buffer()

			if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
				vim.notify("Не удалось создать буфер лога", vim.log.levels.ERROR)
				return
			end

			-- Проверяем, есть ли уже окно с этим буфером
			local existing_winid = nil
			for _, winid in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_get_buf(winid) == bufnr then
					existing_winid = winid
					break
				end
			end

			if existing_winid then
				-- Если окно уже есть, переключаемся на него
				vim.api.nvim_set_current_win(existing_winid)
			else
				-- Иначе создаем новое окно
				local current_win = vim.api.nvim_get_current_win()
				vim.cmd("botright split")
				vim.api.nvim_win_set_buf(0, bufnr)
				vim.api.nvim_win_set_height(0, 20)

				-- Возвращаем фокус на предыдущее окно если нужно
				if vim.api.nvim_win_is_valid(current_win) then
					vim.api.nvim_set_current_win(current_win)
				end
			end
		end, { desc = "Open shared log" })

		vim.keymap.set("n", "<leader>cx", function()
			-- Закрываем окно общего лога
			local bufnr = get_shared_log_buffer()

			for _, winid in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_get_buf(winid) == bufnr then
					vim.api.nvim_win_close(winid, true)
					break
				end
			end
		end, { desc = "Close shared log" })

		vim.keymap.set("n", "<leader>cl", function()
			local bufnr = get_shared_log_buffer()

			if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
				return
			end

			-- Безопасно очищаем буфер
			pcall(function()
				vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
				vim.api.nvim_set_option_value("readonly", false, { buf = bufnr })

				vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
					"╔══════════════════════════════════════════╗",
					"║           CMake Shared Log               ║",
					"║     Все операции в одном окне            ║",
					"╚══════════════════════════════════════════╝",
					"",
					"Лог очищен " .. os.date("%H:%M:%S"),
					"",
				})

				vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
				vim.api.nvim_set_option_value("readonly", true, { buf = bufnr })
			end)
		end, { desc = "Clear shared log" })

		-- Автоматически обновлять compile_commands.json
		vim.api.nvim_create_autocmd("User", {
			pattern = { "CMakeBuildFinished", "CMakeBuildFailed", "CMakeCleanFinished" },
			callback = function()
				vim.defer_fn(function()
					local root = vim.fn.getcwd()
					local source = root .. "/build/compile_commands.json"
					local target = root .. "/compile_commands.json"

					if vim.fn.filereadable(source) == 1 then
						os.execute("cp " .. source .. " " .. target)
						vim.notify("compile_commands.json обновлен", vim.log.levels.INFO)
					end

					-- Добавляем сообщение в общий лог
					add_to_shared_log("Сборка завершена, compile_commands.json обновлен", false)
				end, 300)
			end,
		})
	end,
}

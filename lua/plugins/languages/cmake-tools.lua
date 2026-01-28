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
		M.run_terminal_bufnr = nil -- ID буфера терминала для запуска
		M.run_terminal_winid = nil -- ID окна терминала для запуска

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

			-- Окно консоли
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

		-- Глобальное состояние консоли
		local console_state = {
			winid = nil,
			bufnr = nil,
			is_open = false,
		}

		-- Функция для поиска существующего окна консоли CMake
		local function find_cmake_console_window()
			-- Сначала проверяем сохраненное состояние
			if
				console_state.winid
				and console_state.bufnr
				and vim.api.nvim_win_is_valid(console_state.winid)
				and vim.api.nvim_buf_is_valid(console_state.bufnr)
			then
				-- Проверяем, что это действительно окно консоли
				local bufname = vim.api.nvim_buf_get_name(console_state.bufnr)
				if bufname:match("CMake Console") then
					return console_state.winid, console_state.bufnr
				end
			end

			-- Ищем среди всех окон
			for _, winid in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_is_valid(winid) then
					local bufnr = vim.api.nvim_win_get_buf(winid)
					if vim.api.nvim_buf_is_valid(bufnr) then
						local bufname = vim.api.nvim_buf_get_name(bufnr)
						local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")

						if bufname:match("CMake Console") or (buftype == "nofile" and bufname == "") then
							console_state.winid = winid
							console_state.bufnr = bufnr
							console_state.is_open = true
							return winid, bufnr
						end
					end
				end
			end
			return nil, nil
		end

		-- Функция для открытия/показа общей консоли
		local function open_cmake_console()
			local winid, bufnr = find_cmake_console_window()

			if winid then
				-- Окно уже существует, переключаемся на него
				if vim.api.nvim_win_is_valid(winid) then
					vim.api.nvim_set_current_win(winid)
					vim.cmd("wincmd =")
					-- Прокручиваем вниз
					if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
						vim.api.nvim_buf_call(bufnr, function()
							vim.cmd("normal! G")
						end)
					end
				end
				return winid, bufnr
			else
				-- Создаем новое окно консоли
				vim.cmd("botright split")
				local new_bufnr = vim.api.nvim_create_buf(true, false) -- Создаем новый буфер
				local new_winid = vim.api.nvim_get_current_win()

				-- Настраиваем буфер как консоль
				vim.api.nvim_win_set_buf(new_winid, new_bufnr)
				vim.api.nvim_buf_set_name(new_bufnr, "CMake Console")
				vim.api.nvim_buf_set_option(new_bufnr, "buftype", "nofile")
				vim.api.nvim_buf_set_option(new_bufnr, "bufhidden", "hide")
				vim.api.nvim_buf_set_option(new_bufnr, "swapfile", false)
				vim.api.nvim_buf_set_option(new_bufnr, "filetype", "cmake")
				vim.api.nvim_buf_set_option(new_bufnr, "modifiable", true)
				vim.api.nvim_buf_set_option(new_bufnr, "readonly", false)

				-- Устанавливаем размер окна
				vim.api.nvim_win_set_height(new_winid, 15)

				-- Добавляем заголовок
				vim.api.nvim_buf_set_lines(new_bufnr, 0, -1, false, {
					"╔══════════════════════════════════════════╗",
					"║           CMake Console                  ║",
					"╚══════════════════════════════════════════╝",
					"",
				})

				-- Сохраняем состояние
				console_state.winid = new_winid
				console_state.bufnr = new_bufnr
				console_state.is_open = true

				-- Автоматическое обновление состояния при закрытии
				vim.api.nvim_create_autocmd("WinClosed", {
					buffer = new_bufnr,
					once = true,
					callback = function()
						console_state.winid = nil
						console_state.bufnr = nil
						console_state.is_open = false
					end,
				})

				return new_winid, new_bufnr
			end
		end

		-- Функция для добавления сообщения в общую консоль
		local function add_to_cmake_console(message, is_error)
			local winid, bufnr = open_cmake_console()

			if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
				-- Включаем возможность редактирования
				vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
				vim.api.nvim_buf_set_option(bufnr, "readonly", false)

				local lines = vim.split(message, "\n")
				local current_lines = vim.api.nvim_buf_line_count(bufnr)

				-- Добавляем разделитель если уже есть содержание
				if current_lines > 5 then
					vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
						"────────────────────────────────────────────",
					})
				end

				-- Добавляем временную метку
				local timestamp = os.date("%H:%M:%S")
				vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
					"[" .. timestamp .. "] " .. (is_error and "❌ " or "✅ ") .. lines[1],
				})

				-- Добавляем остальные строки
				if #lines > 1 then
					for i = 2, #lines do
						vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {
							"        " .. lines[i],
						})
					end
				end

				-- Прокручиваем вниз
				vim.api.nvim_buf_call(bufnr, function()
					vim.cmd("normal! G")
				end)

				-- Возвращаем режим только для чтения для безопасности
				vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
				vim.api.nvim_buf_set_option(bufnr, "readonly", true)
			end
		end

		-- Универсальная функция для выполнения команд с общей консолью
		local function execute_with_console(action_func, action_name)
			-- Открываем консоль
			local winid, bufnr = open_cmake_console()
			local current_win = vim.api.nvim_get_current_win()

			if winid and bufnr then
				-- Добавляем сообщение о начале операции
				add_to_cmake_console("Начало: " .. action_name, false)

				-- Возвращаемся в предыдущее окно
				if vim.api.nvim_win_is_valid(current_win) then
					vim.api.nvim_set_current_win(current_win)
				end

				-- Выполняем действие асинхронно
				vim.defer_fn(function()
					local success, result = pcall(action_func)

					-- Добавляем результат в консоль
					if success then
						add_to_cmake_console("Завершено: " .. action_name, false)
					else
						add_to_cmake_console("Ошибка: " .. tostring(result), true)
					end
				end, 100)
			else
				-- Если не удалось открыть консоль, просто выполняем действие
				action_func()
				vim.notify(action_name, vim.log.levels.INFO)
			end
		end

		-- Функция для поиска существующего окна терминала для запуска
		local function find_run_terminal_window()
			-- Проверяем, есть ли сохраненный ID окна и он все еще валиден
			if M.run_terminal_winid and vim.api.nvim_win_is_valid(M.run_terminal_winid) then
				local bufnr = vim.api.nvim_win_get_buf(M.run_terminal_winid)
				local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
				if buftype == "terminal" then
					return M.run_terminal_winid, bufnr
				end
			end

			-- Ищем среди всех окон
			for _, winid in ipairs(vim.api.nvim_list_wins()) do
				local bufnr = vim.api.nvim_win_get_buf(winid)
				local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
				local bufname = vim.api.nvim_buf_get_name(bufnr)

				-- Проверяем, что это терминал и имя буфера содержит сигнатуру запуска
				if buftype == "terminal" and (bufname:match("term://") or vim.api.nvim_buf_get_name(bufnr) == "") then
					M.run_terminal_winid = winid
					M.run_terminal_bufnr = bufnr
					return winid, bufnr
				end
			end

			return nil, nil
		end

		-- Функция для корректной очистки терминала
		local function clear_terminal_and_run(bufnr, winid, command)
			-- Проверяем валидность входных данных
			if
				not winid
				or not bufnr
				or not vim.api.nvim_win_is_valid(winid)
				or not vim.api.nvim_buf_is_valid(bufnr)
			then
				-- Просто создаем новый терминал
				vim.cmd("split")
				vim.cmd("terminal " .. command)
				vim.cmd("startinsert")

				M.run_terminal_winid = vim.api.nvim_get_current_win()
				M.run_terminal_bufnr = vim.api.nvim_get_current_buf()
				vim.api.nvim_win_set_height(M.run_terminal_winid, 15)
				return true
			end

			-- Сохраняем текущее окно
			local current_win = vim.api.nvim_get_current_win()

			-- Переходим в окно терминала
			vim.api.nvim_set_current_win(winid)

			-- Выходим из режима вставки если находимся в нем
			vim.cmd("stopinsert")

			-- Закрываем старое окно
			vim.api.nvim_win_close(winid, true)

			-- Удаляем старый буфер
			if vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_buf_delete(bufnr, { force = true })
			end

			-- Создаем новый терминал
			vim.cmd("split")
			vim.cmd("terminal " .. command)
			vim.cmd("startinsert")

			-- Сохраняем новые ID
			M.run_terminal_winid = vim.api.nvim_get_current_win()
			M.run_terminal_bufnr = vim.api.nvim_get_current_buf()

			-- Устанавливаем размер окна
			vim.api.nvim_win_set_height(M.run_terminal_winid, 15)

			-- Возвращаемся в предыдущее окно
			if vim.api.nvim_win_is_valid(current_win) then
				vim.api.nvim_set_current_win(current_win)
			end

			-- Автоматическое удаление при закрытии окна
			vim.api.nvim_create_autocmd("WinClosed", {
				buffer = M.run_terminal_bufnr,
				once = true,
				callback = function()
					M.run_terminal_winid = nil
					M.run_terminal_bufnr = nil
				end,
			})

			return true
		end

		-- Функция для закрытия существующего терминала запуска
		local function close_run_terminal()
			local winid, bufnr = find_run_terminal_window()
			if winid then
				-- Останавливаем процесс в терминале
				local job_id = bufnr and vim.api.nvim_buf_get_var(bufnr, "terminal_job_id")
				if job_id then
					pcall(vim.fn.chansend, job_id, "\003") -- Ctrl+C
					vim.fn.wait(200, function() end)
				end

				-- Закрываем окно и буфер
				if vim.api.nvim_win_is_valid(winid) then
					vim.api.nvim_win_close(winid, true)
				end
				if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
					vim.api.nvim_buf_delete(bufnr, { force = true })
				end

				M.run_terminal_winid = nil
				M.run_terminal_bufnr = nil
			end
		end

		-- Функция для принудительного открытия/показа консоли ПЕРЕД действием
		local function ensure_console_open_and_execute(action_func, action_name)
			-- Сначала проверяем, есть ли уже окно консоли
			local winid, bufnr = find_cmake_console_window()

			if winid then
				-- Окно уже существует, переключаемся на него
				vim.api.nvim_set_current_win(winid)
				vim.cmd("wincmd =") -- перераспределить размеры окон
				-- Прокручиваем вниз, чтобы видеть свежие сообщения
				vim.api.nvim_buf_call(bufnr, function()
					vim.cmd("normal! G")
				end)
			else
				-- Окна нет, используем API cmake-tools
				local cmake_api = require("cmake-tools")

				-- Открываем консоль через API если доступно
				local success, result = pcall(function()
					-- Пробуем разные способы открыть консоль
					if cmake_api.open then
						cmake_api.open()
					elseif cmake_api.show_console then
						cmake_api.show_console()
					else
						-- Используем внутреннюю функцию плагина
						require("cmake-tools.ui").open_console()
					end
				end)

				if not success then
					-- Если API недоступно, создаем окно вручную
					vim.cmd("split")
					vim.cmd("enew")
					vim.api.nvim_buf_set_name(0, "CMake Console")
					vim.bo.buftype = "nofile"
					vim.bo.bufhidden = "hide"
					vim.api.nvim_buf_set_lines(0, 0, -1, false, {
						"CMake Console",
						"══════════════════════════════════════════",
						"Используйте :CMakeGenerate, :CMakeBuild и т.д.",
						"══════════════════════════════════════════",
					})
					winid = vim.api.nvim_get_current_win()
					bufnr = vim.api.nvim_get_current_buf()
				end

				-- Ждем немного и прокручиваем вниз
				vim.defer_fn(function()
					local new_winid, new_bufnr = find_cmake_console_window()
					if new_winid then
						vim.api.nvim_buf_call(new_bufnr, function()
							vim.cmd("normal! G")
						end)
					end
				end, 100)
			end

			-- Возвращаемся в предыдущее окно и выполняем действие
			vim.defer_fn(function()
				vim.cmd("wincmd p") -- возврат в предыдущее окно

				if action_func then
					action_func()
				end

				if action_name then
					vim.notify(action_name, vim.log.levels.INFO)
				end
			end, 150)
		end

		-- Горячие клавиши с гарантированным открытием консоли
		vim.keymap.set("n", "<leader>cg", function()
			execute_with_console(function()
				cmake.generate({})
			end, "Генерация CMake...")
		end, { desc = "CMake Generate" })

		vim.keymap.set("n", "<leader>cb", function()
			execute_with_console(function()
				cmake.build({})
			end, "Сборка проекта...")
		end, { desc = "CMake Build" })

		-- Запуск без аргументов
		vim.keymap.set("n", "<leader>cr", function()
			execute_with_console(function()
				cmake.run({})
			end, "Запуск проекта...")
		end, { desc = "CMake Run" })

		-- Функция для поиска исполняемого файла
		local function find_executable(target)
			local possible_paths = {
				"./build/" .. target,
				"./build/Debug/" .. target,
				"./build/Release/" .. target,
				"./build/bin/" .. target,
				"./build/Debug/bin/" .. target,
				"./build/Release/bin/" .. target,
			}

			for _, path in ipairs(possible_paths) do
				if vim.fn.executable(path) == 1 then
					return path
				end
			end

			-- Если не нашли, используем find
			local handle = io.popen("find build -name '" .. target .. "' -type f -executable 2>/dev/null | head -1")
			if handle then
				local found = handle:read("*a"):gsub("%s+$", "")
				handle:close()
				return found ~= "" and found or nil
			end

			return nil
		end

		-- Запуск с аргументами
		vim.keymap.set("n", "<leader>cR", function()
			-- Получаем текущую цель
			local target = nil

			-- Попробуем получить цель из cmake-tools
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
				return
			end

			-- Строим команду для запуска
			local cmd = exe_path
			if args_input ~= "" then
				cmd = cmd .. " " .. args_input
			end

			vim.notify("Запускаю: " .. cmd, vim.log.levels.INFO)

			-- Проверяем, есть ли уже окно терминала
			local winid, bufnr = find_run_terminal_window()

			if winid and bufnr then
				-- Окно существует, очищаем и запускаем новую команду
				clear_terminal_and_run(bufnr, winid, cmd)
			else
				-- Создаем новое окно терминала
				vim.cmd("split") -- Вертикальное разделение
				vim.cmd("terminal " .. cmd)
				vim.cmd("startinsert")

				-- Сохраняем ID окна и буфера
				M.run_terminal_winid = vim.api.nvim_get_current_win()
				M.run_terminal_bufnr = vim.api.nvim_get_current_buf()

				-- Устанавливаем размер окна
				vim.api.nvim_win_set_height(M.run_terminal_winid, 15)

				-- Автоматическое удаление при закрытии окна
				vim.api.nvim_create_autocmd("WinClosed", {
					buffer = M.run_terminal_bufnr,
					once = true,
					callback = function()
						M.run_terminal_winid = nil
						M.run_terminal_bufnr = nil
					end,
				})
			end

			-- Автоматическое обновление при закрытии окна
			vim.api.nvim_create_autocmd("WinClosed", {
				buffer = terminal_bufnr,
				once = true,
				callback = function()
					M.run_terminal_winid = nil
					M.run_terminal_bufnr = nil
				end,
			})

			-- Возвращаем фокус в предыдущее окно
			if vim.api.nvim_win_is_valid(current_win) then
				vim.api.nvim_set_current_win(current_win)
			end

			-- Показываем уведомление
			vim.notify(
				"Запущено: " .. target .. (args_input ~= "" and " с аргументами" or ""),
				vim.log.levels.INFO
			)
		end, { desc = "CMake Run with args" })

		-- Закрытие терминала
		vim.keymap.set("n", "<leader>cz", function()
			close_run_terminal()
			vim.notify("Терминал запуска закрыт", vim.log.levels.INFO)
		end, { desc = "Close run terminal" })

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

		-- Другие команды без консоли
		vim.keymap.set("n", "<leader>cd", "<cmd>CMakeDebug<cr>", { desc = "CMake Debug" })
		vim.keymap.set("n", "<leader>cc", "<cmd>CMakeClean<cr>", { desc = "CMake Clean" })
		vim.keymap.set("n", "<leader>ct", "<cmd>CMakeSelectTarget<cr>", { desc = "Select Target" })

		vim.keymap.set("n", "<leader>co", function()
			open_cmake_console()
			vim.cmd("startinsert")
		end, { desc = "Open CMake console" })

		vim.keymap.set("n", "<leader>cx", function()
			-- Используем find_cmake_console_window для получения актуального winid
			local winid, bufnr = find_cmake_console_window()
			if winid and vim.api.nvim_win_is_valid(winid) then
				vim.api.nvim_win_close(winid, true)
				console_state.winid = nil
				console_state.bufnr = nil
				console_state.is_open = false
			else
				vim.notify("Консоль CMake не найдена", vim.log.levels.INFO)
			end
		end, { desc = "Close CMake console" })

		-- Очистить консоль
		vim.keymap.set("n", "<leader>cl", function()
			local bufnr = console_state.bufnr
			if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
					"╔══════════════════════════════════════════╗",
					"║           CMake Console                  ║",
					"╚══════════════════════════════════════════╝",
					"",
					"Консоль очищена " .. os.date("%H:%M:%S"),
				})
				vim.api.nvim_buf_call(bufnr, function()
					vim.cmd("normal! G")
				end)
			end
		end, { desc = "Clear CMake console" })

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
					local winid, bufnr = find_cmake_console_window()
					if winid and bufnr then
						-- Переходим в окно консоли
						local current_win = vim.api.nvim_get_current_win()
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
						-- Прокручиваем вниз снова
						vim.api.nvim_buf_call(bufnr, function()
							vim.cmd("normal! G")
						end)
						-- Возвращаемся в предыдущее окно
						vim.api.nvim_set_current_win(current_win)
					end
				end, 1000) -- Ждем дольше для гарантии
			end,
		})

		-- Дополнительно: Хук после открытия консоли
		vim.api.nvim_create_autocmd("User", {
			pattern = "CMakeConsoleOpened",
			callback = function()
				vim.defer_fn(function()
					local winid, bufnr = find_cmake_console_window()
					if winid and bufnr then
						-- Устанавливаем, что буфер не должен закрываться
						vim.bo[bufnr].bufhidden = ""
						vim.bo[bufnr].buflisted = true
						-- Прокручиваем вниз
						vim.api.nvim_buf_call(bufnr, function()
							vim.cmd("normal! G")
						end)
					end
				end, 200)
			end,
		})
	end,
}

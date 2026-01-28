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

		-- Функция для поиска существующего окна консоли CMake
		local function find_cmake_console_window()
			for _, winid in ipairs(vim.api.nvim_list_wins()) do
				local bufnr = vim.api.nvim_win_get_buf(winid)
				local bufname = vim.api.nvim_buf_get_name(bufnr)
				if bufname:match("CMake Console") then
					return winid, bufnr
				end
			end
			return nil, nil
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
			-- Сохраняем текущее окно
			local current_win = vim.api.nvim_get_current_win()

			-- Закрываем старое окно терминала если оно есть
			if winid and vim.api.nvim_win_is_valid(winid) then
				vim.api.nvim_set_current_win(winid)
				-- Выходим из режима вставки если находимся в нем
				vim.cmd("stopinsert")
				-- Закрываем окно
				vim.api.nvim_win_close(winid, true)
			end

			-- Удаляем буфер если он существует
			if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_buf_delete(bufnr, { force = true })
			end

			-- Создаем новое окно терминала
			vim.cmd("split") -- Вертикальное разделение

			-- Используем termopen для большей надежности
			vim.cmd("enew") -- Создаем новый буфер
			local new_bufnr = vim.api.nvim_get_current_buf()

			-- Открываем терминал в этом буфере
			vim.cmd("terminal " .. command)

			-- Переходим в терминальный режим
			vim.cmd("startinsert")

			-- Получаем новые ID
			local new_winid = vim.api.nvim_get_current_win()
			local new_bufnr = vim.api.nvim_get_current_buf()

			-- Сохраняем ID окна и буфера
			M.run_terminal_winid = new_winid
			M.run_terminal_bufnr = new_bufnr

			-- Устанавливаем размер окна
			vim.api.nvim_win_set_height(new_winid, 15)

			-- Возвращаемся в предыдущее окно
			if vim.api.nvim_win_is_valid(current_win) then
				vim.api.nvim_set_current_win(current_win)
			end

			-- Автоматическое удаление при закрытии окна
			vim.api.nvim_create_autocmd("WinClosed", {
				buffer = new_bufnr,
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
				-- Окна нет, создаем новое
				vim.cmd("CMakeOpen")

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
			ensure_console_open_and_execute(function()
				cmake.generate({})
			end, "Генерация CMake...")
		end, { desc = "CMake Generate" })

		vim.keymap.set("n", "<leader>cb", function()
			ensure_console_open_and_execute(function()
				cmake.build({})
			end, "Сборка проекта...")
		end, { desc = "CMake Build" })

		-- Запуск без аргументов
		vim.keymap.set("n", "<leader>cr", function()
			ensure_console_open_and_execute(function()
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

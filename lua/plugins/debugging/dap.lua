-- Конфигурация отладки для C++: nvim-dap + codelldb через mason
-- UI + виртуальный текст для удобства

return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"theHamsta/nvim-dap-virtual-text",
		"nvim-neotest/nvim-nio",
		"williamboman/mason.nvim",
		"jay-babu/mason-nvim-dap.nvim",
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		-- Проверка, что текущая директория — CMake-проект
		local function is_cmake_project()
			local root = vim.fn.getcwd()
			return vim.fn.filereadable(root .. "/CMakeLists.txt") == 1
		end

		-- ============================================
		-- ОТКЛЮЧЕНИЕ ВСТРОЕННОГО JUMP-TO-FRAME
		-- ============================================

		local ok, session_module = pcall(require, "dap.session")
		if ok and session_module and session_module.jump_to_frame then
			local orig_jump_to_frame = session_module.jump_to_frame

			session_module.jump_to_frame = function(self, frame, preserve_focus_hint, stopped)
				if not frame or not frame.source then
					return
				end

				local path = frame.source.path or ""
				local name = frame.source.name or ""

				-- Полный список виртуальных/несуществующих исходников
				if
					path:match("^dap%-src://")
					or path:match("^dap%-repl://")
					or path:match("^dap%-")
					or name:match("^dap%-")
					or path == ""
					or vim.fn.filereadable(path) == 0
				then
					return
				end

				return orig_jump_to_frame(self, frame, preserve_focus_hint, stopped)
			end
		end

		-- ============================================
		-- ЯВНАЯ РЕГИСТРАЦИЯ АДАПТЕРА (на всякий случай)
		-- ============================================

		-- Пробуем получить путь из mason-registry
		local function get_codelldb_path()
			local ok, registry = pcall(require, "mason-registry")
			if ok then
				local ok2, pkg = pcall(registry.get_package, registry, "codelldb")
				if ok2 and pkg:is_installed() then
					local install_path = pkg:get_install_path()
					-- Проверяем несколько возможных путей
					local paths = {
						install_path .. "/extension/adapter/codelldb",
						install_path .. "/adapter/codelldb",
						install_path .. "/codelldb",
					}
					for _, p in ipairs(paths) do
						if vim.fn.executable(p) == 1 then
							return p
						end
					end
				end
			end

			-- Fallback: ищем в PATH
			local path = vim.fn.exepath("codelldb")
			if path and path ~= "" then
				return path
			end

			return nil
		end

		local codelldb_path = get_codelldb_path()
		if not codelldb_path then
			vim.notify("codelldb not found! Install via :MasonInstall codelldb", vim.log.levels.ERROR)
		else
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = codelldb_path,
					args = { "--port", "${port}" },
				},
			}
		end

		-- ============================================
		-- ДИНАМИЧЕСКАЯ ГЕНЕРАЦИЯ КОНФИГУРАЦИИ ИЗ CMAKE
		-- ============================================

		-- Получает текущий preset из cmake-tools или из состояния
		local function get_current_preset()
			local ok, cmake = pcall(require, "cmake-tools")
			if not ok then
				return "debug"
			end

			-- Пробуем разные методы получения preset
			if cmake.get_config_preset then
				local p = cmake.get_config_preset()
				if p and p ~= "" then
					return p
				end
			end

			-- Извлекаем из build directory
			if cmake.get_build_directory then
				local dir = cmake.get_build_directory()
				if dir then
					local preset = tostring(dir):match(".*/build/([^/]+)$")
					if preset then
						return preset
					end
				end
			end

			return "debug"
		end

		---Получает директорию сборки
		local function get_build_dir(preset)
			local ok, cmake = pcall(require, "cmake-tools")
			if ok and cmake.get_build_directory then
				local dir = cmake.get_build_directory()
				if dir and dir ~= "" then
					return tostring(dir)
				end
			end
			return vim.fn.getcwd() .. "/build/" .. (preset or "debug")
		end

		---Проверяет, является ли файл исполняемым
		local function is_executable(path)
			return vim.fn.executable(path) == 1
		end

		---Ищет исполняемые файлы в директории
		local function find_executables(dir)
			local targets = {}
			local handle = vim.loop.fs_scandir(dir)
			if not handle then
				return targets
			end

			while true do
				local name, typ = vim.loop.fs_scandir_next(handle)
				if not name then
					break
				end
				if typ == "file" and is_executable(dir .. "/" .. name) then
					table.insert(targets, name)
				end
			end

			-- Также ищем в поддиректориях (на случай если бинарники в bin/)
			local subdirs = { "bin", "src" }
			for _, sub in ipairs(subdirs) do
				local subdir = dir .. "/" .. sub
				local subhandle = vim.loop.fs_scandir(subdir)
				if subhandle then
					while true do
						local name, typ = vim.loop.fs_scandir_next(subhandle)
						if not name then
							break
						end
						if typ == "file" and is_executable(subdir .. "/" .. name) then
							table.insert(targets, sub .. "/" .. name)
						end
					end
				end
			end

			return targets
		end

		---Получает launch targets из cmake-tools
		local function get_cmake_targets()
			local ok, cmake = pcall(require, "cmake-tools")
			if not ok then
				return nil
			end

			local ok2, targets = pcall(cmake.get_launch_targets)
			if ok2 and targets and #targets > 0 then
				-- Преобразуем в имена файлов (без пути)
				local result = {}
				for _, t in ipairs(targets) do
					-- t может быть строкой или таблицей
					local name = type(t) == "string" and t or (t.name or t)
					table.insert(result, name)
				end
				return result
			end

			return nil
		end

		---Главная функция: создаёт список DAP-конфигураций из CMake
		local function generate_cmake_configs()
			-- Проверка, что текущая директория — CMake-проект
			if not is_cmake_project() then
				return {}
			end

			local preset = get_current_preset()
			local build_dir = get_build_dir(preset)

			-- Проверяем существование build-директории
			local stat = (vim.uv or vim.loop).fs_stat(build_dir)
			if not stat or stat.type ~= "directory" then
				vim.notify(
					"Build directory not found: " .. build_dir .. "\nBuild first: <leader>cb",
					vim.log.levels.WARN
				)
				return {}
			end

			-- Получаем targets
			local targets = get_cmake_targets()
			if not targets then
				targets = find_executables(build_dir)
			end

			if #targets == 0 then
				vim.notify("No executables found in " .. build_dir, vim.log.levels.WARN)
				return {}
			end

			-- Создаём конфигурацию для каждого target
			local configs = {}
			for _, target in ipairs(targets) do
				local program_path = build_dir .. "/" .. target
				-- Проверяем что файл существует
				local fstat = (vim.uv or vim.loop).fs_stat(program_path)
				if fstat and fstat.type == "file" then
					table.insert(configs, {
						name = string.format("Debug: %s [%s]", target, preset),
						type = "codelldb",
						request = "launch",
						program = program_path, -- ПРЯМОЙ ПУТЬ, без функций input
						cwd = "${workspaceFolder}",
						stopOnEntry = false,
						console = "integratedTerminal",
					})
				end
			end

			return configs
		end

		-- ============================================
		-- ПЕРЕОПРЕДЕЛЕНИЕ КОНФИГУРАЦИИ ДЛЯ C/C++
		-- ============================================

		---@diagnostic disable-next-line: undefined-field
		dap.configurations = dap.configurations or {}

		-- Функция, которая будет вызываться при запросе конфигураций
		local function setup_cpp_configs()
			local configs = generate_cmake_configs()
			if #configs > 0 then
				---@diagnostic disable-next-line: undefined-field
				dap.configurations.cpp = configs
				---@diagnostic disable-next-line: undefined-field
				dap.configurations.c = configs
			else
				---@diagnostic disable-next-line: undefined-field
				dap.configurations.cpp = {
					{
						name = "Debug (manual path)",
						type = "codelldb",
						request = "launch",
						program = function()
							return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
						end,
						cwd = "${workspaceFolder}",
						stopOnEntry = false,
						console = "integratedTerminal",
					},
				}
				---@diagnostic disable-next-line: undefined-field
				dap.configurations.c = dap.configurations.cpp
			end
		end

		-- Обновляем конфигурации при входе в C++ файл
		vim.api.nvim_create_autocmd("BufEnter", {
			pattern = { "*.cpp", "*.c", "*.h", "*.hpp", "*.cc", "*.cxx" },
			callback = setup_cpp_configs,
		})

		-- Инициализируем сразу
		setup_cpp_configs()

		-- ============================================
		-- ПОВЕДЕНИЕ ПРИ ОСТАНОВКЕ НА BREAKPOINT
		-- ============================================

		-- Отключаем автооткрытие frame'ов в текущем окне
		-- nvim-dap по умолчанию использует 'jump_to_frame' listener,
		-- который открывает код в текущем окне, заменяя буфер.
		-- Мы переопределяем это: открываем в существующем окне с кодом.

		-- Удаляем стандартный listener для jump_to_frame
		---@diagnostic disable-next-line: undefined-field
		dap.listeners.after.event_stopped["dapui_config"] = nil

		-- ============================================
		-- КАСТОМНЫЙ JUMP (без dap-src)
		-- ============================================

		dap.listeners.after.event_stopped["custom_jump"] = function(session, body)
			local thread_id = body.threadId
			if not thread_id then
				return
			end

			session:request("stackTrace", { threadId = thread_id, startFrame = 0, levels = 1 }, function(err, response)
				if err or not response or not response.stackFrames or #response.stackFrames == 0 then
					return
				end

				local frame = response.stackFrames[1]
				if not frame.source or not frame.source.path then
					return
				end

				local source_path = frame.source.path
				if source_path:match("^dap%-") or vim.fn.filereadable(source_path) == 0 then
					return
				end

				local line = frame.line or 1

				vim.schedule(function()
					for _, win in ipairs(vim.api.nvim_list_wins()) do
						local buf = vim.api.nvim_win_get_buf(win)
						local buftype = vim.bo[buf].buftype
						if buftype == "" then
							pcall(function()
								vim.api.nvim_win_call(win, function()
									vim.cmd("keepalt edit " .. vim.fn.fnameescape(source_path))
									local bufnr = vim.api.nvim_win_get_buf(win)
									local line_count = vim.api.nvim_buf_line_count(bufnr)
									vim.api.nvim_win_set_cursor(win, { math.min(line, line_count), 0 })
								end)
							end)
							return
						end
					end
				end)
			end)
		end

		-- ============================================
		-- ИКОНКИ
		-- ============================================

		vim.fn.sign_define("DapBreakpoint", {
			text = "🛑",
			texthl = "DiagnosticSignError",
			linehl = "",
			numhl = "",
		})
		vim.fn.sign_define("DapBreakpointRejected", {
			text = "🚫",
			texthl = "DiagnosticSignError",
			linehl = "",
			numhl = "",
		})
		vim.fn.sign_define("DapStopped", {
			text = "➤",
			texthl = "DiagnosticSignWarn",
			linehl = "debugPC",
			numhl = "",
		})

		-- ============================================
		-- DAP-UI
		-- ============================================

		dapui.setup({
			-- Раскладка окон
			layouts = {
				-- ВЕРХНЯЯ ПАНЕЛЬ (основная): переменные, стек, точки останова
				{
					elements = {
						{
							id = "scopes",
							size = 0.35, -- Переменные (Locals, Globals)
						},
						{
							id = "watches",
							size = 0.20, -- Watch expressions
						},
						{
							id = "stacks",
							size = 0.25, -- Call stack
						},
						{
							id = "breakpoints",
							size = 0.20, -- Breakpoints list
						},
					},
					size = 18, -- Высота в строках
					position = "bottom",
				},
			},

			-- Настройка отображения значений
			render = {
				max_value_lines = 50,
				max_type_length = 40,
				indent = 2,
			},

			-- Иконки
			icons = {
				expanded = "▾",
				collapsed = "▸",
				current_frame = "▸",
				circular = "↺",
			},

			-- Floating windows (для hover и т.д.)
			floating = {
				border = "rounded",
				max_height = 0.8,
				max_width = 0.8,
				mappings = {
					close = { "q", "<Esc>" },
				},
			},

			-- Панель управления (play, pause, step over и т.д.)
			controls = {
				enabled = true,
				element = "scopes", -- Показывать controls над REPL
				icons = {
					pause = "⏸",
					play = "▶",
					step_into = "⏎",
					step_over = "⏭",
					step_out = "⏮",
					step_back = "b",
					run_last = "▶▶",
					terminate = "⏹",
					disconnect = "⏏",
				},
			},

			-- Настройка отдельных элементов
			element_mappings = {},
			expand_lines = true,
			force_buffers = true,

			-- Настройка отображения для каждого элемента
			mappings = {
				-- Стандартные маппинги внутри dap-ui
				edit = "e",
				expand = { "<CR>", "<2-LeftMouse>" },
				open = "o",
				remove = "d",
				repl = "r",
				toggle = "t",
			},
		})

		-- Автооткрытие/закрытие UI
		dap["listeners"].after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap["listeners"].before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap["listeners"].before.event_exited["dapui_config"] = function()
			dapui.close()
		end

		-- Отключаем автооткрытие REPL при остановке
		dap.listeners.after.event_stopped["repl"] = nil
		dap.listeners.after.event_stopped["dap.repl"] = nil

		-- ============================================
		-- KEYMAPS
		-- ============================================

		local opts = { noremap = true, silent = true }

		vim.keymap.set("n", "<F5>", function()
			setup_cpp_configs()
			dap.continue()
		end, vim.tbl_extend("force", opts, { desc = "DAP Continue" }))
		vim.keymap.set("n", "<F10>", function()
			dap.step_over()
		end, vim.tbl_extend("force", opts, { desc = "DAP Step Over" }))
		vim.keymap.set("n", "<F11>", function()
			dap.step_into()
		end, vim.tbl_extend("force", opts, { desc = "DAP Step Into" }))
		vim.keymap.set("n", "<F12>", function()
			dap.step_out()
		end, vim.tbl_extend("force", opts, { desc = "DAP Step Out" }))
		vim.keymap.set("n", "<leader>db", function()
			dap.toggle_breakpoint()
		end, vim.tbl_extend("force", opts, { desc = "DAP Toggle Breakpoint" }))
		vim.keymap.set("n", "<leader>B", function()
			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end, vim.tbl_extend("force", opts, { desc = "DAP Conditional Breakpoint" }))
		vim.keymap.set("n", "<leader>du", function()
			dapui.toggle()
		end, vim.tbl_extend("force", opts, { desc = "DAP UI" }))
		vim.keymap.set("n", "<leader>dC", function()
			dap.run()
		end, vim.tbl_extend("force", opts, { desc = "DAP Select Config" }))

		-- 💡 Команда для ввода/сохранения аргументов вручную
		vim.api.nvim_create_user_command("DapSelectConfig", function()
			dap.run()
		end, { desc = "Select DAP configuration" })
		vim.keymap.set("n", "<leader>dl", function()
			local log_path = vim.fn.stdpath("cache") .. "/dap.log"
			vim.cmd("edit " .. log_path)
		end, { desc = "DAP Logs" })
	end,
}

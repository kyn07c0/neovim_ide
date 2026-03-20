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
		local osys = require("cmake-tools.osys")

		-- Хранилище состояния
		local M = {
			current_preset = nil,
			current_build_type = "Debug",
			runner_args = {},
		}

		-- Определение доступных пресетов
		local function get_presets()
			local presets = { "debug", "release", "profile", "asan", "tsan" }
			local available = {}

			for _, preset in ipairs(presets) do
				-- Проверяем существование папки сборки как признак использования
				local build_dir = vim.fn.getcwd() .. "/build/" .. preset
				table.insert(available, {
					name = preset,
					active = vim.fn.isdirectory(build_dir) == 1,
				})
			end

			return available
		end

		-- Форматирование имени пресета для отображения
		local function format_preset_name(preset)
			local icons = {
				debug = "🔧",
				release = "⚡",
				profile = "📊",
				asan = "🛡️",
				tsan = "🔒",
				default = "📦",
			}
			local names = {
				debug = "Debug + Tests + Sanitizers",
				release = "Release Optimized",
				profile = "Profile Build",
				asan = "Address Sanitizer",
				tsan = "Thread Sanitizer",
				default = "Default",
			}

			local icon = icons[preset] or icons.default
			local name = names[preset] or preset
			local active = M.current_preset == preset and " ✓" or ""

			return string.format("%s %s%s", icon, name, active)
		end

		-- Настраиваем плагин так, чтобы он не создавал свои терминалы
		cmake.setup({
			cmake_command = "cmake",

			-- Используем CMakePresets.json вместо ручной настройки
			cmake_use_preset = true,
			cmake_preset = "debug", -- пресет по умолчанию

			-- Окно консоли для сборки и генерации
			cmake_console_size = 50, -- размер консоли снизу
			cmake_show_console = "always", -- всегда показывать консоль
			cmake_close_console_on_success = false, -- не закрывать при успехе
			cmake_close_console_on_failure = false, -- не закрывать при ошибке
			cmake_console_position = "below", -- позиция окна
			cmake_console_floating = false, -- не плавающее окно
			cmake_console_interval = 50, -- интервал обновления вывода
			cmake_build_options = { "--verbose" }, -- подробный вывод
			cmake_console_height = 50, -- явная высота
			cmake_console_title = "CMake Console", -- заголовок окна
			cmake_console_autoscroll = true, -- автоматическая прокрутка

			-- Интеграция с dap
			cmake_dap_configuration = {
				name = "cpp",
				type = "codelldb",
				request = "launch",
				stopOnEntry = false,
				runInTerminal = true,
				console = "integratedTerminal",
			},

			-- Дополнительные настройки для надежности
			cmake_variants_message = {
				short = { show = true },
				long = { show = true, max_length = 50 },
			},

			-- Отключаем встроенный запуск программ
			cmake_runner = {
				run = false, -- Не использовать встроенный runner
			},
		})

		-- ==================== КОМАНДЫ ВЫБОРА ПРОФИЛЯ ====================

		-- Выбор CMake Preset
		vim.keymap.set("n", "<leader>cp", function()
			local presets = get_presets()
			local options = {}

			for _, p in ipairs(presets) do
				table.insert(options, format_preset_name(p.name))
			end

			vim.ui.select(options, {
				prompt = "Выберите профиль сборки:",
				format_item = function(item)
					return item
				end,
			}, function(choice, idx)
				if not choice then
					return
				end

				local selected = presets[idx].name
				M.current_preset = selected

				-- Обновляем compile_commands.json
				vim.defer_fn(function()
					local root = vim.fn.getcwd()
					local source = root .. "/build/" .. selected .. "/compile_commands.json"
					local target = root .. "/compile_commands.json"

					if vim.fn.filereadable(source) == 1 then
						os.execute("ln -sf " .. source .. " " .. target)
					end

					-- Перезапускаем LSP для новых флагов компиляции
					vim.cmd("LspRestart")
				end, 500)

				vim.notify("Профиль: " .. selected, vim.log.levels.INFO)
			end)
		end, { desc = "CMake: Select Preset" })

		-- Быстрое переключение Debug ↔ Release
		vim.keymap.set("n", "<leader>c<space>", function()
			local new_preset = M.current_preset == "debug" and "release" or "debug"
			M.current_preset = new_preset

			vim.notify("Переключено на: " .. new_preset, vim.log.levels.INFO)

			-- Предлагаем пересобрать
			vim.ui.select({ "Да", "Нет" }, {
				prompt = "Перегенерировать CMake для " .. new_preset .. "?",
			}, function(choice)
				if choice == "Да" then
					cmake.generate({ preset = new_preset })
				end
			end)
		end, { desc = "CMake: Toggle Debug/Release" })

		-- ==================== СБОРКА ====================

		-- Сборка с текущим пресетом
		vim.keymap.set("n", "<leader>cb", function()
			local preset = M.current_preset or "debug"
			cmake.build({ preset = preset })
		end, { desc = "CMake: Build (current preset)" })

		-- Чистая сборка (rebuild)
		vim.keymap.set("n", "<leader>cB", function()
			local preset = M.current_preset or "debug"

			vim.ui.select({ "Да", "Нет" }, {
				prompt = "Clean + Build для " .. preset .. "?",
			}, function(choice)
				if choice == "Да" then
					cmake.clean()
					vim.defer_fn(function()
						cmake.build({ preset = preset })
					end, 500)
				end
			end)
		end, { desc = "CMake: Clean Build" })

		-- ==================== ЗАПУСК И ОТЛАДКА ====================

		-- Запуск с выбором цели
		vim.keymap.set("n", "<leader>cr", function()
			-- Получаем список исполняемых целей
			local targets = cmake.get_launch_targets() or {}

			if #targets == 0 then
				vim.notify(
					"Нет исполняемых целей. Сначала соберите проект.",
					vim.log.levels.WARN
				)
				return
			end

			vim.ui.select(targets, {
				prompt = "Выберите цель для запуска:",
			}, function(target)
				if not target then
					return
				end

				-- Сохраняем аргументы для этой цели
				local args = M.runner_args[target] or ""

				if args ~= "" then
					vim.ui.select({
						"С аргументами: " .. args,
						"Без аргументов",
						"Изменить аргументы",
					}, {
						prompt = "Аргументы для " .. target .. ":",
					}, function(choice, idx)
						if idx == 1 then
							cmake.launch({ target = target, args = vim.split(args, " ") })
						elseif idx == 2 then
							cmake.launch({ target = target })
						elseif idx == 3 then
							local new_args = vim.fn.input("Аргументы: ", args)
							M.runner_args[target] = new_args
							cmake.launch({ target = target, args = vim.split(new_args, " ") })
						end
					end)
				else
					cmake.launch({ target = target })
				end
			end)
		end, { desc = "CMake: Run Target" })

		-- Запуск с аргументами
		vim.keymap.set("n", "<leader>cR", function()
			local target = cmake.get_launch_target()
			if not target then
				vim.notify("Не выбрана цель запуска", vim.log.levels.WARN)
				return
			end

			local args = vim.fn.input("Аргументы для " .. target .. ": ", M.runner_args[target] or "")

			M.runner_args[target] = args
			cmake.launch({
				target = target,
				args = args ~= "" and vim.split(args, " ") or nil,
			})
		end, { desc = "CMake: Run with Args" })

		-- Отладка текущей цели
		vim.keymap.set("n", "<leader>cd", function()
			cmake.debug()
		end, { desc = "CMake: Debug" })

		-- ==================== УПРАВЛЕНИЕ ====================

		-- Генерация (configure)
		vim.keymap.set("n", "<leader>cg", function()
			cmake.generate({ preset = M.current_preset })
		end, { desc = "CMake: Generate" })

		-- Чистка
		vim.keymap.set("n", "<leader>cc", function()
			cmake.clean()
		end, { desc = "CMake: Clean" })

		-- Полная очистка (удаление build/)
		vim.keymap.set("n", "<leader>cC", function()
			local build_dir = vim.fn.getcwd() .. "/build"

			vim.ui.select({ "Да", "Нет" }, {
				prompt = "Удалить всю папку build/?",
			}, function(choice)
				if choice == "Да" then
					vim.fn.system("rm -rf " .. build_dir)
					vim.notify("Build directory removed", vim.log.levels.INFO)
				end
			end)
		end, { desc = "CMake: Purge Build" })

		-- Просмотр текущей конфигурации
		vim.keymap.set("n", "<leader>ci", function()
			local info = {
				"CMake Configuration:",
				"  Preset: " .. (M.current_preset or "не выбран"),
				"  Build Dir: build/" .. (M.current_preset or "???"),
				"  Type: " .. (M.current_preset == "release" and "Release" or "Debug"),
			}

			-- Добавляем информацию о цели
			local target = cmake.get_launch_target()
			table.insert(info, "  Target: " .. (target or "не выбрана"))

			-- Добавляем аргументы если есть
			if target and M.runner_args[target] then
				table.insert(info, "  Args: " .. M.runner_args[target])
			end

			vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
		end, { desc = "CMake: Info" })

		-- ==================== АВТОМАТИЗАЦИЯ ====================

		-- Автоматическая генерация при открытии проекта
		vim.api.nvim_create_autocmd("BufReadPost", {
			pattern = { "*.cpp", "*.h", "*.hpp", "CMakeLists.txt" },
			group = vim.api.nvim_create_augroup("CMakeAutoSetup", { clear = true }),
			once = true,
			callback = function()
				-- Проверяем наличие compile_commands.json
				local root = vim.fn.getcwd()
				local compile_db = root .. "/compile_commands.json"

				if vim.fn.filereadable(compile_db) == 0 then
					-- Проверяем есть ли build директории
					local has_debug = vim.fn.isdirectory(root .. "/build/debug") == 1
					local has_release = vim.fn.isdirectory(root .. "/build/release") == 1

					if has_debug or has_release then
						-- Есть сборка, линкуем compile_commands.json
						local preset = has_debug and "debug" or "release"
						local source = root .. "/build/" .. preset .. "/compile_commands.json"

						if vim.fn.filereadable(source) == 1 then
							os.execute("ln -sf " .. source .. " " .. compile_db)
							vim.notify("Linked compile_commands.json from " .. preset, vim.log.levels.INFO)
						end
					else
						-- Нет сборки — предлагаем создать
						vim.defer_fn(function()
							vim.ui.select({ "debug", "release", "Пропустить" }, {
								prompt = "Сгенерировать CMake?",
							}, function(choice)
								if choice and choice ~= "Пропустить" then
									local preset = choice
									M.current_preset = preset
									cmake.generate({ preset = preset })
								end
							end)
						end, 1000)
					end
				end
			end,
		})

		-- Авто-обновление compile_commands.json после сборки
		vim.api.nvim_create_autocmd("User", {
			pattern = { "CMakeBuildFinished" },
			callback = function()
				local root = vim.fn.getcwd()
				local preset = M.current_preset or "debug"
				local source = root .. "/build/" .. preset .. "/compile_commands.json"
				local target = root .. "/compile_commands.json"

				if vim.fn.filereadable(source) == 1 then
					os.execute("ln -sf " .. source .. " " .. target)
				end
			end,
		})

		-- Сохранение/восстановление состояния между сессиями
		local session_file = vim.fn.stdpath("cache") .. "/cmake_state.json"

		vim.api.nvim_create_autocmd("VimLeavePre", {
			callback = function()
				local state = {
					preset = M.current_preset,
					args = M.runner_args,
				}
				local file = io.open(session_file, "w")
				if file then
					file:write(vim.json.encode(state))
					file:close()
				end
			end,
		})

		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				local file = io.open(session_file, "r")
				if file then
					local content = file:read("*all")
					file:close()
					local ok, state = pcall(vim.json.decode, content)
					if ok then
						M.current_preset = state.preset
						M.runner_args = state.args or {}
					end
				end
			end,
		})
	end,
}

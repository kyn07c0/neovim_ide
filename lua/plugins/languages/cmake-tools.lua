-- Интеграция с CMake (build, run, debug)

return {
	"civitasv/cmake-tools.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "mfussenegger/nvim-dap" },
	ft = { "cmake", "cpp", "c" }, -- загружаем для CMake-файлов

	config = function()
		local function is_cmake_project()
			local root = vim.fn.getcwd()
			return vim.fn.filereadable(root .. "/CMakeLists.txt") == 1
		end

		local cmake = require("cmake-tools")
		local root = vim.fn.getcwd()

		-- Если нет CMakeLists.txt — отключаем плагин
		if vim.fn.filereadable(root .. "/CMakeLists.txt") ~= 1 then
			vim.notify(
				"cmake-tools: не CMake-проект, плагин не активирован",
				vim.log.levels.INFO
			)
			return
		end

		-- Хранилище состояния
		local M = {
			current_preset = "debug",
			runner_args = {},
		}

		-- Форматирование имени пресета для отображения
		local function format_preset_name(preset)
			local icons =
				{ debug = "🔧", release = "⚡", profile = "📊", asan = "🛡️", tsan = "🔒", default = "📦" }
			local names = {
				debug = "Debug + Tests",
				release = "Release Optimized",
				profile = "Profile",
				asan = "ASan",
				tsan = "TSan",
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

			-- Отключаем встроенный запуск программ
			cmake_runner = {
				run = false, -- Не использовать встроенный runner
			},
		})

		-- ==================== КОМАНДЫ ВЫБОРА ПРОФИЛЯ ====================

		vim.keymap.set("n", "<leader>cp", function()
			local presets = { "debug", "release", "profile", "asan", "tsan" }
			vim.ui.select(
				presets,
				{ prompt = "Выберите профиль сборки:", format_item = format_preset_name },
				function(choice)
					if not choice then
						return
					end
					M.current_preset = choice
					vim.defer_fn(function()
						local root_path = vim.fn.getcwd()
						local source = root_path .. "/build/" .. choice .. "/compile_commands.json"
						local target = root_path .. "/compile_commands.json"
						if vim.fn.filereadable(source) == 1 then
							os.execute("ln -sf " .. source .. " " .. target)
						end
						vim.cmd("LspRestart")
					end, 500)
					vim.notify("Профиль: " .. choice, vim.log.levels.INFO)
				end
			)
		end, { desc = "CMake: Select Preset" })

		vim.keymap.set("n", "<leader>c<space>", function()
			local new = M.current_preset == "debug" and "release" or "debug"
			M.current_preset = new
			vim.notify("Переключено на: " .. new, vim.log.levels.INFO)
			vim.ui.select(
				{ "Да", "Нет" },
				{ prompt = "Перегенерировать CMake для " .. new .. "?" },
				function(c)
					if c == "Да" then
						cmake.generate({ preset = new })
					end
				end
			)
		end, { desc = "CMake: Toggle Debug/Release" })

		vim.keymap.set("n", "<leader>cb", function()
			if not is_cmake_project() then
				vim.notify("Это не CMake-проект (нет CMakeLists.txt)", vim.log.levels.INFO)
				return
			end
			cmake.build({ preset = M.current_preset or "debug" })
		end, { desc = "CMake: Build" })
		vim.keymap.set("n", "<leader>cB", function()
			local preset = M.current_preset or "debug"
			vim.ui.select({ "Да", "Нет" }, { prompt = "Clean + Build для " .. preset .. "?" }, function(c)
				if c == "Да" then
					cmake.clean()
					vim.defer_fn(function()
						cmake.build({ preset = preset })
					end, 500)
				end
			end)
		end, { desc = "CMake: Clean Build" })

		-- Команда запуска с аргументами и DAP-интеграцией
		vim.keymap.set("n", "<leader>cr", function()
			if not is_cmake_project() then
				vim.notify("Это не CMake-проект (нет CMakeLists.txt)", vim.log.levels.WARN)
				return
			end
			local targets = cmake.get_launch_targets() or {}
			if #targets == 0 then
				vim.notify(
					"Нет целей. Сначала соберите проект (<leader>cb).",
					vim.log.levels.WARN
				)
				return
			end

			vim.ui.select(targets, { prompt = "Цель для запуска:" }, function(target)
				if not target then
					return
				end

				local preset = M.current_preset or "debug"
				local build_dir = vim.fn.getcwd() .. "/build/" .. preset
				local program = build_dir .. "/" .. target

				vim.ui.select({
					"▶ Запустить",
					"🐛 Отладить (DAP)",
					"⚙️ С аргументами",
					"🐛 Отладить с аргументами",
				}, { prompt = "Действие для " .. target }, function(_, idx)
					if idx == 1 then
						cmake.launch({ target = target })
					elseif idx == 2 then
						local dap = require("dap")
						dap.run({
							name = "Debug: " .. target,
							type = "codelldb",
							request = "launch",
							program = program,
							cwd = "${workspaceFolder}",
							stopOnEntry = false,
							console = "integratedTerminal",
						})
					elseif idx == 3 then
						local args = vim.fn.input("Аргументы: ")
						cmake.launch({ target = target, args = vim.split(args, "%s+") })
					elseif idx == 4 then
						local args = vim.fn.input("Аргументы: ")
						local dap = require("dap")
						dap.run({
							name = "Debug: " .. target,
							type = "codelldb",
							request = "launch",
							program = program,
							args = vim.split(args, "%s+"),
							cwd = "${workspaceFolder}",
							stopOnEntry = false,
							console = "integratedTerminal",
						})
					end
				end)
			end)
		end, { desc = "CMake: Run Target" })

		vim.keymap.set("n", "<leader>cd", function()
			if not is_cmake_project() then
				vim.notify("Это не CMake-проект", vim.log.levels.WARN)
				return
			end
			local preset = M.current_preset or "debug"
			local build_dir = vim.fn.getcwd() .. "/build/" .. preset

			-- Убедимся, что проект собран
			local targets = cmake.get_launch_targets() or {}
			if #targets == 0 then
				vim.notify("Нет собранных targets. Запускаем сборку...", vim.log.levels.WARN)
				cmake.build({ preset = preset })
				return
			end

			-- Запускаем DAP с первым target (или можно добавить выбор)
			local target = targets[1]
			local program = build_dir .. "/" .. target

			local dap = require("dap")
			dap.run({
				name = "CMake Debug: " .. target,
				type = "codelldb",
				request = "launch",
				program = program,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
				console = "integratedTerminal",
			})
		end, { desc = "CMake: Debug Target (DAP)" })

		vim.keymap.set("n", "<leader>cg", function()
			if not is_cmake_project() then
				vim.notify("Это не CMake-проект", vim.log.levels.WARN)
				return
			end
			cmake.generate({ preset = M.current_preset })
		end, { desc = "CMake: Generate" })
		vim.keymap.set("n", "<leader>cc", function()
			if not is_cmake_project() then
				vim.notify("Это не CMake-проект", vim.log.levels.WARN)
				return
			end
			cmake.clean()
		end, { desc = "CMake: Clean" })
		vim.keymap.set("n", "<leader>cC", function()
			vim.ui.select({ "Да", "Нет" }, { prompt = "Удалить всю папку build/?" }, function(c)
				if c == "Да" then
					vim.fn.system("rm -rf build")
				end
			end)
		end, { desc = "CMake: Purge Build" })

		vim.api.nvim_create_autocmd("User", {
			pattern = "CMakeBuildFinished",
			callback = function()
				local source = root .. "/build/" .. (M.current_preset or "debug") .. "/compile_commands.json"
				if vim.fn.filereadable(source) == 1 then
					os.execute("ln -sf " .. source .. " " .. root .. "/compile_commands.json")
				end
			end,
		})

		local session_file = vim.fn.stdpath("cache") .. "/cmake_state.json"
		vim.api.nvim_create_autocmd("VimLeavePre", {
			callback = function()
				local f = io.open(session_file, "w")
				if f then
					f:write(vim.json.encode({ preset = M.current_preset, args = M.runner_args }))
					f:close()
				end
			end,
		})
		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				local f = io.open(session_file, "r")
				if f then
					local ok, st = pcall(vim.json.decode, f:read("*all"))
					f:close()
					if ok then
						M.current_preset = st.preset
						M.runner_args = st.args or {}
					end
				end
			end,
		})
	end,
}

-- Конфигурация отладки для C++: nvim-dap + codelldb через mason
-- UI + виртуальный текст для удобства

return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui", -- UI панели (variables, stacks, repl)
		"theHamsta/nvim-dap-virtual-text", -- значения переменных в коде
		"jay-babu/mason-nvim-dap.nvim", -- мост mason → dap (автоустановка codelldb)
		"nvim-neotest/nvim-nio", -- зависимость dap-ui (asyncio-like)
	},

	config = function()
		-- Загружаем модули с проверкой
		local dap_ok, dap = pcall(require, "dap")
		if not dap_ok then
			vim.notify("nvim-dap не загружен", vim.log.levels.ERROR)
			return
		end

		local dapui_ok, dapui = pcall(require, "dapui")
		if not dapui_ok then
			vim.notify("dap-ui не загружен", vim.log.levels.ERROR)
			return
		end

		-- Автоустановка codelldb через mason-nvim-dap
		local mason_dap_ok, mason_dap = pcall(require, "mason-nvim-dap")
		if mason_dap_ok then
			mason_dap.setup({
				ensure_installed = { "codelldb" }, -- устанавливаем codelldb автоматически
				automatic_installation = true,
				handlers = {}, -- используем дефолтные обработчики (рекомендуется)
			})
		end

		-- Настройка адаптера codelldb
		dap.adapters.codelldb = {
			type = "server",
			port = "${port}",
			executable = {
				command = "codelldb", -- mason добавит в PATH
				args = { "--port", "${port}" },
			},
		}

		-- Конфигурация запуска для C++ (launch: запуск программы)
		dap.configurations.cpp = {
			{
				name = "Launch (codelldb)",
				type = "codelldb",
				request = "launch",
				program = function()
					-- Запрашиваем путь к исполняемому файлу (можно автоматизировать через CMake)
					return vim.fn.input("Path: ", vim.fn.getcwd() .. "/build/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false, -- не останавливаться на main
				args = {}, -- аргументы программы (можно vim.fn.input для ввода)
				runInTerminal = false,

				-- Дополнительно: если используешь CMake + compile_commands.json
				-- env = { LLDB_LAUNCH_FLAG_LAUNCH_IN_TTY = "YES" },
			},
			-- Опционально: attach к запущенному процессу
			{
				name = "Attach to process",
				type = "codelldb",
				request = "attach",
				pid = require("dap.utils").pick_process,
				cwd = "${workspaceFolder}",
			},
		}

		-- Копируем конфиг cpp → c (если нужно)
		dap.configurations.c = dap.configurations.cpp

		-- UI настройка (автооткрытие/закрытие при debug)
		dapui.setup({
			icons = {
				expanded = "▾",
				collapsed = "▸",
				current_frame = "▸",
			},
			mappings = {
				expand = { "<CR>", "<2-LeftMouse>" },
				open = "o",
				remove = "d",
				edit = "e",
				repl = "r",
				toggle = "t",
			},
			layouts = {
				{
					elements = {
						{ id = "scopes", size = 0.25 },
						{ id = "breakpoints", size = 0.25 },
						{ id = "stacks", size = 0.25 },
						{ id = "watches", size = 0.25 },
					},
					size = 40,
					position = "left",
				},
				{
					elements = {
						{ id = "repl", size = 0.5 },
						{ id = "console", size = 0.5 },
					},
					size = 0.25,
					position = "bottom",
				},
			},
			controls = {
				enabled = true,
				element = "repl",
				icons = {
					pause = "⏸",
					play = "▶",
					step_into = "⏬",
					step_over = "⏭",
					step_out = "⏮",
					step_back = "⏪",
					run_last = "⏯",
					terminate = "⏹",
				},
			},
			floating = {
				max_height = nil,
				max_width = nil,
				border = "single",
				mappings = {
					close = { "q", "<Esc>" },
				},
			},
			windows = { indent = 1 },
			render = {
				max_type_length = nil,
				max_value_lines = 100,
			},
		})

		-- Автооткрытие UI при старте/остановке
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end

		-- Виртуальный текст (значения переменных в коде)
		local dap_virtual_text_ok = pcall(require, "nvim-dap-virtual-text")
		if dap_virtual_text_ok then
			require("nvim-dap-virtual-text").setup({
				enabled = true,
				enabled_commands = true,
				highlight_changed_variables = true,
				highlight_new_as_changed = true,
				show_stop_reason = true,
				commented = false,
			})
		end

		-- Интеграция с Telescope
		local telescope_ok = pcall(require, "telescope")
		if telescope_ok then
			require("telescope").load_extension("dap")
		end

		-- Настройка dap-go (если используете)
		local dap_go_ok = pcall(require, "dap-go")
		if dap_go_ok then
			require("dap-go").setup()
		end

		-- Горячие клавиши для отладки (можно вынести в отдельный файл)
		local opts = { noremap = true, silent = true }
		vim.keymap.set("n", "<F5>", dap.continue, opts)
		vim.keymap.set("n", "<F10>", dap.step_over, opts)
		vim.keymap.set("n", "<F11>", dap.step_into, opts)
		vim.keymap.set("n", "<F12>", dap.step_out, opts)
		vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, opts)
		vim.keymap.set("n", "<leader>B", function()
			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end, opts)
		vim.keymap.set("n", "<leader>dr", dap.repl.toggle, opts)
		vim.keymap.set("n", "<leader>du", dapui.toggle, opts)

		-- Горячие клавиши для Telescope DAP
		vim.keymap.set("n", "<leader>dc", "<cmd>Telescope dap commands<cr>", { desc = "DAP commands" })
		vim.keymap.set("n", "<leader>dbp", "<cmd>Telescope dap list_breakpoints<cr>", { desc = "DAP breakpoints" })
	end,
}

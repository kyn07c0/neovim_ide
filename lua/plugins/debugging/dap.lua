-- Конфигурация отладки для C++: nvim-dap + codelldb через mason
-- UI + виртуальный текст для удобства

return {
	-- Основной плагин DAP
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			-- Интерфейс (панели, переменные, стек вызовов)
			"rcarriga/nvim-dap-ui",
			-- Виртуальный текст (значения переменных прямо в коде)
			"theHamsta/nvim-dap-virtual-text",
			-- Асинхронная библиотека
			"nvim-neotest/nvim-nio",
			-- Иконки (опционально, если не используете nvim-web-devicons)
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- 1. Настройка знаков (иконки для брейкпоинтов и т.д.)
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
				linehl = "",
				numhl = "",
			})

			-- 2. Настройка nvim-dap-ui
			dapui.setup({
				icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
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
						position = "left",
						size = 40,
					},
					{
						elements = {
							{ id = "repl", size = 0.5 },
							{ id = "console", size = 0.5 },
						},
						position = "bottom",
						size = 10,
					},
				},
				controls = {
					element = "repl",
					enabled = true,
				},
			})

			-- 3. Автоматическое открытие/закрытие UI при старте/конце отладки
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- 4. Конфигурация адаптеров (Примеры для популярных языков)

			--- Python (debugpy)
			dap.adapters.python = {
				type = "executable",
				command = "python", -- Или путь к конкретному venv: "/path/to/venv/bin/python"
				args = { "-m", "debugpy.adapter" },
			}
			dap.configurations.python = {
				{
					type = "python",
					request = "launch",
					name = "Launch file",
					program = "${file}", -- Текущий файл
					pythonPath = function()
						return vim.fn.exepath("python")
					end,
				},
			}

			--- C/C++ (codelldb - рекомендуется для modern C++)
			-- Убедитесь, что codelldb установлен (например, через mason.nvim или вручную)
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = "codelldb", -- Команда в PATH
					args = { "--port", "${port}" },
				},
			}
			dap.configurations.cpp = {
				{
					name = "Launch file",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}
			-- Для C часто копируют конфиг cpp
			dap.configurations.c = dap.configurations.cpp

			--- Node.js / TypeScript (js-debug-adapter)
			-- Требует установки адаптера, часто через mason или npm install -g @vscode/js-debug
			dap.adapters.node2 = {
				type = "executable",
				command = "node",
				args = {
					os.getenv("HOME")
						.. "/.local/share/nvim/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
					"${port}",
				},
			}
			dap.configurations.typescript = {
				{
					type = "node2",
					request = "attach",
					program = "${file}",
					cwd = vim.fn.getcwd(),
					sourceMaps = true,
					protocol = "inspector",
					console = "integratedTerminal",
				},
			}

			-- 5. Клавиши управления (Keymaps)
			local keymap = vim.keymap.set
			local opts = { noremap = true, silent = true }

			keymap("n", "<leader>dB", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, opts)
			keymap("n", "<leader>db", function()
				dap.toggle_breakpoint()
			end, opts)
			keymap("n", "<leader>dc", function()
				dap.continue()
			end, opts)
			keymap("n", "<leader>da", function()
				dap.terminate()
			end, opts) -- Abort
			keymap("n", "<leader>de", function()
				dap.step_out()
			end, opts)
			keymap("n", "<leader>di", function()
				dap.step_into()
			end, opts)
			keymap("n", "<leader>do", function()
				dap.step_over()
			end, opts)
			keymap("n", "<leader>dr", function()
				dap.run_last()
			end, opts)
			keymap("n", "<leader>du", function()
				dapui.toggle()
			end, opts)
			keymap("n", "<leader>dh", function()
				require("dap.ui.widgets").hover()
			end, opts) -- Hover variables
		end,
	},
}

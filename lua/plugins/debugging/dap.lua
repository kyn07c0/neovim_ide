-- Конфигурация отладки для C++: nvim-dap + codelldb через mason
-- UI + виртуальный текст для удобства

return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"theHamsta/nvim-dap-virtual-text", -- Зависимость для виртуального текста
		"nvim-neotest/nvim-nio",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		-- 1. Иконки отладки (исправлены лишние пробелы в названиях знаков)
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

		-- 2. Настройка dap-ui (Минимализм: только консоль внизу)
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
					elements = { "scopes", "console" },
					position = "bottom",
					size = 15, -- Высота окна консоли
				},
			},
			render = {
				max_type_length = nil,
				max_value_lines = 100,
			},
			floating = {
				max_height = nil,
				max_width = nil,
				border = "rounded",
				mappings = {
					close = { "q", "<Esc>" },
				},
			},
		})

		-- 3. Автоматическое управление UI
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end

		-- 4. Адаптеры (Исправлены имена и пути)

		--- C/C++ (codelldb)
		dap.adapters.codelldb = {
			type = "server",
			port = "${port}",
			executable = {
				command = "codelldb",
				args = { "--port", "${port}" },
			},
		}

		-- Умная функция для пути к исполняемому файлу
		local function get_cpp_program()
			-- Попытка угадать путь (например, build/main или просто спросить)
			local default_path = vim.fn.getcwd() .. "/build/main"
			return vim.fn.input("Path to executable: ", default_path, "file")
		end

		dap.configurations.cpp = {
			{
				name = "Launch file (C++)",
				type = "codelldb",
				request = "launch",
				program = get_cpp_program,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
			},
		}
		dap.configurations.c = dap.configurations.cpp

		--- Python (debugpy) - оставлен как опция
		dap.adapters.python = {
			type = "executable",
			command = "python",
			args = { "-m", "debugpy.adapter" },
		}
		dap.configurations.python = {
			{
				type = "python",
				request = "launch",
				name = "Launch file",
				program = "${file}",
				pythonPath = function()
					return vim.fn.exepath("python")
				end,
			},
		}

		-- 5. Клавиши (Keymaps)
		local keymap = vim.keymap.set
		local opts = { noremap = true, silent = true }

		-- Отладка
		keymap("n", "<leader>db", function()
			dap.toggle_breakpoint()
		end, opts)
		keymap("n", "<leader>dB", function()
			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end, opts)
		keymap("n", "<leader>dc", function()
			dap.continue()
		end, opts)
		keymap("n", "<leader>da", function()
			dap.terminate()
		end, opts)

		-- Шагание
		keymap("n", "<leader>di", function()
			dap.step_into()
		end, opts)
		keymap("n", "<leader>do", function()
			dap.step_over()
		end, opts)
		keymap("n", "<leader>de", function()
			dap.step_out()
		end, opts)

		-- UI и прочее
		keymap("n", "<leader>du", function()
			dapui.toggle()
		end, opts)
		keymap("n", "<leader>dr", function()
			dap.run_last()
		end, opts)
		keymap("n", "<leader>dh", function()
			require("dap.ui.widgets").hover()
		end, opts)

		-- Оценка выражения в текущей строке (полезно вместе с virtual-text)
		keymap("n", "<leader>dv", function()
			require("dap").eval(vim.fn.expand("<cword>"))
		end, opts)
	end,
}

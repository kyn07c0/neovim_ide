-- Конфигурация отладки для C++: nvim-dap + codelldb через mason
-- UI + виртуальный текст для удобства

return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"theHamsta/nvim-dap-virtual-text", -- Зависимость для виртуального текста
		"nvim-neotest/nvim-nio",
		"williamboman/mason.nvim",
		"jay-babu/mason-nvim-dap.nvim",
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
			linehl = "debugPC",
			numhl = "",
		})

		-- 2. Настройка dap-ui (Минимализм: только консоль внизу)
		dapui.setup({
			layouts = {
				{
					elements = {
						{ id = "scopes", size = 1.0 },
					},
					size = 0.25,
					position = "right",
				},
				{
					elements = { "repl" },
					size = 0.25,
					position = "bottom",
				},
			},
			floating = { border = "rounded" },
			controls = { enabled = true },
		})

		-- Автооткрытие/закрытие UI
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
			_adapterSettings = {
				showDisassembly = "never",
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

				showDisassembly = "never", -- варианты: "always", "auto", "never"
				disassembly = { -- опционально, но полезно
					syntaxHighlighting = false,
				},
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
		local opts = { noremap = true, silent = true }

		vim.keymap.set("n", "<F5>", function()
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
		vim.keymap.set("n", "<leader>dr", function()
			dap.repl.toggle()
		end, vim.tbl_extend("force", opts, { desc = "DAP REPL" }))
		vim.keymap.set("n", "<leader>du", function()
			dapui.toggle()
		end, vim.tbl_extend("force", opts, { desc = "DAP UI" }))
	end,
}

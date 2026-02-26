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
		require("mason-nvim-dap").setup({
			ensure_installed = { "codelldb" },
			automatic_installation = true,
			handlers = {
				function(config)
					require("mason-nvim-dap").default_setup(config)
				end,
				codelldb = function(config)
					config.configurations = {
						{
							name = "Launch",
							type = "codelldb",
							request = "launch",
							program = function()
								return vim.fn.input("Path: ", vim.fn.getcwd() .. "/build/main", "file")
							end,
							cwd = "${workspaceFolder}",
							stopOnEntry = false,
						},
					}
					require("mason-nvim-dap").default_setup(config)
				end,
			},
		})

		local dap = require("dap")
		local dapui = require("dapui")

		-- Иконки отладки (исправлены лишние пробелы в названиях знаков)
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

		-- Настройка dap-ui (Минимализм: только консоль внизу)
		dapui.setup({
			layouts = {
				{
					elements = {
						{ id = "scopes", size = 0.5 },
						{ id = "repl", size = 0.5 },
					},
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

		-- Путь к исполняемому файлу
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

				args = function()
					local args_str = vim.fn.input("Program arguments (space separated): ")
					-- Разбиваем строку на таблицу, если строка не пустая
					if args_str and args_str ~= "" then
						local args = {}
						for arg in args_str:gmatch("%S+") do
							table.insert(args, arg)
						end
						return args
					end
					return {}
				end,

				-- Отключаем ассемблер через LLDB команды (выполняются после старта)
				setupCommands = {
					{
						text = "-gdb-set disassembly-flavor intel",
						description = "Set disassembly flavor to intel",
						ignoreFailures = true,
					},
				},
			},
		}
		dap.configurations.c = dap.configurations.cpp

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

		-- Команда для просмотра логов
		vim.keymap.set("n", "<leader>dl", function()
			local log_path = vim.fn.stdpath("cache") .. "/dap.log"
			vim.cmd("edit " .. log_path)
		end, { desc = "DAP Logs" })
	end,
}

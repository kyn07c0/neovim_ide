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
				codelldb = function(config)
					config.configurations = {
						{
							name = "Launch C++",
							type = "codelldb",
							request = "launch",
							program = function()
								return vim.fn.input("Path: ", vim.fn.getcwd() .. "/build/main", "file")
							end,
							cwd = "${workspaceFolder}",
							stopOnEntry = false,
							initCommands = {
								"settings set target.x86-disassembly-flavor intel",
							},
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
						{
							id = "scopes",
							size = 0.6,
							-- Фильтруем ненужные scope типы
							filters = {
								exclude = { "static", "Static" }, -- Скрываем Static
							},
						},
						{ id = "watches", size = 0.2 },
						{ id = "repl", size = 0.2 },
					},
					size = 0.30,
					position = "bottom",
				},
			},
			-- Настройка отображения значений
			render = {
				max_value_lines = 100, -- Ограничиваем строки для значений
				max_type_length = 30, -- Сокращаем длинные типы
				indent = 1, -- Компактные отступы
			},
			-- Настройка иконок для разных типов переменных
			icons = {
				expanded = "▾",
				collapsed = "▸",
				current_frame = "▸",
			},
			floating = {
				border = "rounded",
				max_height = 0.8,
				max_width = 0.8,
				mappings = {
					close = { "q", "<Esc>" },
				},
			},
			controls = {
				enabled = true,
				element = "repl",
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
			mappings = {}, -- Пустая таблица, используются умолчания
			element_mappings = {}, -- Пустая таблица
			expand_lines = true, -- Значение по умолчанию
			force_buffers = true, -- Значение по умолчанию
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

		local opts = { noremap = true, silent = true }

		vim.keymap.set("n", "<F5>", function()
			dap["continue"]()
		end, vim.tbl_extend("force", opts, { desc = "DAP Continue" }))
		vim.keymap.set("n", "<F10>", function()
			dap["step_over"]()
		end, vim.tbl_extend("force", opts, { desc = "DAP Step Over" }))
		vim.keymap.set("n", "<F11>", function()
			dap["step_into"]()
		end, vim.tbl_extend("force", opts, { desc = "DAP Step Into" }))
		vim.keymap.set("n", "<F12>", function()
			dap["step_out"]()
		end, vim.tbl_extend("force", opts, { desc = "DAP Step Out" }))
		vim.keymap.set("n", "<leader>db", function()
			dap["toggle_breakpoint"]()
		end, vim.tbl_extend("force", opts, { desc = "DAP Toggle Breakpoint" }))
		vim.keymap.set("n", "<leader>B", function()
			dap["set_breakpoint"](vim.fn.input("Breakpoint condition: "))
		end, vim.tbl_extend("force", opts, { desc = "DAP Conditional Breakpoint" }))
		vim.keymap.set("n", "<leader>dr", function()
			dap["repl.toggle"]()
		end, vim.tbl_extend("force", opts, { desc = "DAP REPL" }))
		vim.keymap.set("n", "<leader>du", function()
			dapui.toggle()
		end, vim.tbl_extend("force", opts, { desc = "DAP UI" }))
		vim.keymap.set("n", "<leader>dC", function()
			dap["run"]()
		end, vim.tbl_extend("force", opts, { desc = "DAP Select Config" }))
		vim.api.nvim_create_user_command("DapSelectConfig", function()
			dap["run"]()
		end, { desc = "Select DAP configuration" })

		-- Команда для просмотра логов
		vim.keymap.set("n", "<leader>dl", function()
			local log_path = vim.fn.stdpath("cache") .. "/dap.log"
			vim.cmd("edit " .. log_path)
		end, { desc = "DAP Logs" })
	end,
}

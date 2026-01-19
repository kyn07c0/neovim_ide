-- Конфигурация отладки для C++: nvim-dap + codelldb через mason
-- UI + виртуальный текст для удобства

return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui", -- UI панели (variables, stacks, repl)
		"theHamsta/nvim-dap-virtual-text", -- значения переменных в коде
		"jay-babu/mason-nvim-dap.nvim", -- мост mason → dap (автоустановка codelldb)
		"nvim-neotest/nvim-nio", -- зависимость dap-ui (asyncio-like)
        "leoluz/nvim-dap-go",  -- Адаптер для Go (если multi-lang)
	},

	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		-- Автоустановка codelldb через mason-nvim-dap
		require("mason-nvim-dap").setup({
			ensure_installed = { "codelldb" }, -- устанавливаем codelldb автоматически
			automatic_installation = true,
			handlers = {}, -- используем дефолтные обработчики (рекомендуется)
		})

		-- Настройка адаптера codelldb (mason-nvim-dap сам подхватит путь)
		dap.adapters.codelldb = function(callback, config)
			-- Если нужно вручную — раскомментируй и используй mason-registry
			-- local mason_registry = require("mason-registry")
			-- local codelldb = mason_registry.get_package("codelldb")
			-- local extension_path = codelldb:get_install_path() .. "/extension/"
			-- local codelldb_path = extension_path .. "adapter/codelldb"

			callback({
				type = "server",
				port = "${port}",
				host = "127.0.0.1",
				executable = {
					command = "codelldb", -- mason добавит в PATH
					args = { "--port", "${port}" },
				},
			})
		end

		-- Конфигурация запуска для C++ (launch: запуск программы)
		dap.configurations.cpp = {
			{
				name = "Launch (codelldb)",
				type = "codelldb",
				request = "launch",
				program = function()
					-- Запрашиваем путь к исполняемому файлу (можно автоматизировать через CMake)
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
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
			layouts = {
				{
					elements = { "scopes", "breakpoints", "stacks", "watches" },
					size = 40,
					position = "left",
				},
				{
					elements = { "repl", "console" },
					size = 0.25,
					position = "bottom",
				},
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
		require("nvim-dap-virtual-text").setup({
			enabled = true,
			enabled_commands = true,
			highlight_changed_variables = true,
			highlight_new_as_changed = true,
			show_stop_reason = true,
			commented = false,
		})

        -- Интеграция с Telescope
        require("telescope").load_extension("dap") 

        -- Настройка dap-go (если используете)
        require("dap-go").setup()

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

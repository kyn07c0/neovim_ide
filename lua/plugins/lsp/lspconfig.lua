-- Плагин для настройки всех LSP-серверов

return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
	},
	config = function()
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		-- Расширения для семантических токенов
		capabilities.textDocument.semanticTokens = {
			dynamicRegistration = true,
			tokenTypes = {
				"namespace",
				"type",
				"class",
				"enum",
				"interface",
				"struct",
				"typeParameter",
				"parameter",
				"variable",
				"property",
				"enumMember",
				"event",
				"function",
				"method",
				"macro",
				"keyword",
				"modifier",
				"comment",
				"string",
				"number",
				"regexp",
				"operator",
			},
			tokenModifiers = {
				"declaration",
				"definition",
				"readonly",
				"static",
				"deprecated",
				"abstract",
				"async",
				"modification",
				"documentation",
				"defaultLibrary",
			},
			formats = { "relative" },
		}

		-- Настраиваем clangd через vim.lsp.config
		vim.lsp.config("clangd", {
			capabilities = capabilities,

			cmd = {
				"clangd",
				"--background-index", -- Фоновое индексирование ВСЕХ файлов
				"--background-index-priority=normal", -- Нормальный приоритет вместо low
				"--clang-tidy",
				"--header-insertion=iwyu",
				"--completion-style=detailed",
				"--fallback-style=llvm",
				"--all-scopes-completion", -- Автодополнение из всех файлов
				"--compile-commands-dir=build", -- Путь к compile_commands.json
				"--function-arg-placeholders",
				"--query-driver=/usr/bin/g++", -- компилятор
				"--offset-encoding=utf-8", -- Явно указываем кодировку
				"--pch-storage=memory", -- Оптимизация для больших проектов
				"--malloc-trim", -- Освобождение памяти
				"--pretty", -- Красивый вывод
				"--enable-config", -- Разрешить .clangd конфиг
				-- Оптимизация для больших проектов
				"--limit-results=50", -- Без ограничений результатов
				"--limit-references=100", -- ← ограничиваем референсы
				"--rename-file-limit=50", -- ← ограничиваем переименования
			},

			-- fallback-флаги, если нет compile_commands.json
			init_options = {
				compilationDatabasePath = ".", -- путь к compile_commands.json
				fallbackFlags = { "-std=c++20" },
				clangdFileStatus = true,
				usePlaceholders = true,
				completeUnimported = true, -- Дополнение из неимпортированных файлов
			},

			-- filetypes остаются те же
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
			root_markers = { ".clangd", "compile_commands.json", ".git", "CMakeLists.txt" },

			-- on_attach — вызывается после присоединения клиента к буферу
			on_attach = function(client, bufnr)
				-- Отключаем форматирование от clangd (используем conform)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false

				local opts = { noremap = true, silent = true, buffer = bufnr }
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
				vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, opts)
			end,
		})

		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					runtime = { version = "LuaJIT" },
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
						checkThirdParty = false,
					},
				},
			},
		})

		-- Включаем clangd (он теперь стартует автоматически для filetypes)
		vim.lsp.enable("clangd")
		vim.lsp.enable("lua_ls")

		-- Настройки диагностики (остаются без изменений)
		vim.diagnostic.config({
			virtual_text = true,
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "󰅚 ",
					[vim.diagnostic.severity.WARN] = "󰀪 ",
					[vim.diagnostic.severity.HINT] = "󰌶 ",
					[vim.diagnostic.severity.INFO] = " ",
				},
			},

			underline = true,
			update_in_insert = false,
			severity_sort = true,
		})

		-- Команда LspRestart для Neovim
		vim.api.nvim_create_user_command("LspRestart", function()
			local clients = vim.lsp.get_active_clients()
			if #clients == 0 then
				vim.notify("Нет активных LSP клиентов", vim.log.levels.WARN)
				return
			end
			for _, client in ipairs(clients) do
				vim.lsp.stop_client(client.id, true)
			end
			vim.notify("LSP клиенты перезапущены", vim.log.levels.INFO)
			-- Переоткрываем текущий буфер для повторного подключения
			vim.cmd("edit " .. vim.fn.expand("%:p"))
		end, { desc = "Перезапустить LSP серверы" })
	end,
}

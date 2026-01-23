-- Плагин для настройки всех LSP-серверов

return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		local capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

		-- Настраиваем clangd через vim.lsp.config
		vim.lsp.config("clangd", {
			capabilities = capabilities,

			cmd = {
				"clangd",
				"--background-index",
				"--clang-tidy",
				"--header-insertion=iwyu",
				"--completion-style=detailed",
				"--fallback-style=llvm",
				"--query-driver=/usr/bin/g++", -- компилятор
				"--offset-encoding=utf-8", -- Явно указываем кодировку
				"--pch-storage=memory", -- Оптимизация для больших проектов
				"--malloc-trim", -- Освобождение памяти
				"--pretty", -- Красивый вывод
			},

			-- fallback-флаги, если нет compile_commands.json
			init_options = {
				compilationDatabasePath = "build", -- путь к compile_commands.json
				fallbackFlags = {
					"-std=c++20",
					"-I/usr/include/dpdk",
					"-I/usr/include/libnl3",
				},
				clangdFileStatus = true,
				usePlaceholders = false,
			},

			-- filetypes остаются те же
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },

			-- Оптимизация производительности
			handlers = {
				["textDocument/semanticTokens/full"] = function(_, _, params, client_id, _, config)
					-- Отключаем семантические токены для больших файлов
					local uri = params.textDocument.uri
					local bufnr = vim.uri_to_bufnr(uri)
					local line_count = vim.api.nvim_buf_line_count(bufnr)

					if line_count > 5000 then
						-- Пропускаем семантические токены для больших файлов
						return {}
					end
					-- Используем стандартный обработчик для маленьких файлов
					return vim.lsp.handlers["textDocument/semanticTokens/full"](_, _, params, client_id, _, config)
				end,
			},

			-- Уменьшаем нагрузку
			flags = {
				debounce_text_changes = 150,
				allow_incremental_sync = true,
			},

			-- Настройки для clangd
			settings = {
				clangd = {
					arguments = {
						"--limit-results=100", -- Ограничить количество результатов
						"--header-insertion-decorators", -- Украшения для заголовков
						"--background-index-priority=low", -- Низкий приоритет индексации
					},
					completion = {
						enable = true,
						detailedLabel = true,
						placeholder = false, -- Используйте настройку из .clangd
					},
					diagnostics = {
						enable = true,
						frequency = "idle", -- Проверять в фоне
					},
					memoryLimit = 4096, -- 4GB лимит памяти
				},
			},

			-- on_attach — вызывается после присоединения клиента к буферу
			on_attach = function(client, bufnr)
				-- Отключаем семантические токены для больших файлов
				local line_count = vim.api.nvim_buf_line_count(bufnr)
				if line_count > 5000 then
					client.server_capabilities.semanticTokensProvider = nil
				end

				-- Отключаем форматирование от LSP
				client.server_capabilities.documentFormattingProvider = true
				client.server_capabilities.documentRangeFormattingProvider = true

				local opts = { noremap = true, silent = true, buffer = bufnr }

				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
				vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

				-- Отключаем форматирование от LSP для C/C++ (используем conform.nvim)
				if vim.bo.filetype == "cpp" or vim.bo.filetype == "c" then
					client.server_capabilities.documentFormattingProvider = false
					print("LSP форматирование отключено для C/C++")
				end
			end,
		})

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
					runtime = {
						version = "LuaJIT",
					},
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
						checkThirdParty = false,
					},
				},
			},
		})

		-- Включаем clangd (он теперь стартует автоматически для filetypes)
		vim.lsp.enable("clangd")

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
	end,
}

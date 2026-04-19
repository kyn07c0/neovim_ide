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
				"--limit-results=50", -- Без ограничений результатов
				"--limit-references=100", -- ограничиваем референсы
				"--rename-file-limit=50", -- ограничиваем переименования
				"--enable-config",
			},

			-- fallback-флаги, если нет compile_commands.json
			init_options = {
				compilationDatabasePath = ".", -- путь к compile_commands.json
				fallbackFlags = { "-std=c++20" },
				clangdFileStatus = true,
				usePlaceholders = true,
				completeUnimported = true, -- Дополнение из неимпортированных файлов
				index = {
					enable = true,
					standard = "c++20",
				},
			},

			-- filetypes остаются те же
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
			root_markers = { ".clangd", "compile_commands.json", ".git", "CMakeLists.txt" },

			-- on_attach — вызывается после присоединения клиента к буферу
			on_attach = function(client, bufnr)
				local opts = { noremap = true, silent = true, buffer = bufnr }
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
				vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
				vim.keymap.set("n", "K", function()
					vim.lsp.buf.hover({
						border = "rounded",
						max_width = 80,
						max_height = 20,
						focusable = true,
						focus = false,
					})
				end, { noremap = true, silent = true })
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

		-- Команда для проверки всех файлов проекта
		vim.api.nvim_create_user_command("CheckAllFiles", function()
			local root = vim.fn.getcwd()
			local files = vim.fn.globpath(root, "**/*.cpp", false, true)
			vim.list_extend(files, vim.fn.globpath(root, "**/*.h", false, true))
			vim.list_extend(files, vim.fn.globpath(root, "**/*.hpp", false, true))

			vim.notify("Проверка " .. #files .. " файлов...", vim.log.levels.INFO)

			for i, file in ipairs(files) do
				vim.cmd("silent! edit " .. file)
				vim.cmd("silent! write")
				if i % 10 == 0 then
					vim.notify("Обработано " .. i .. "/" .. #files .. " файлов", vim.log.levels.INFO)
				end
			end

			vim.notify(
				"Проверка завершена! Ошибки показаны в диагностике",
				vim.log.levels.INFO
			)
		end, { desc = "Проверить все файлы проекта на ошибки" })

		-- Команда LspRestart для Neovim
		vim.api.nvim_create_user_command("LspRestart", function()
			local bufnr = vim.api.nvim_get_current_buf()
			---@diagnostic disable-next-line: deprecated
			local clients = vim.lsp.buf_get_clients(bufnr)

			if not clients or vim.tbl_isempty(clients) then
				vim.notify("Нет активных LSP клиентов", vim.log.levels.WARN)
				return
			end

			for client_id, _ in pairs(clients) do
				vim.lsp.stop_client(client_id, true)
			end

			vim.notify("LSP клиенты перезапущены", vim.log.levels.INFO)
			vim.cmd("edit " .. vim.fn.expand("%:p"))
		end, { desc = "Перезапустить LSP серверы" })
	end,
}

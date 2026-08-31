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

		-- Настраиваем clangd через vim.lsp.config
		vim.lsp.config("clangd", {

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

			-- Отключаем documentFormattingProvider, чтобы не дублировать
			capabilities = vim.tbl_deep_extend("force", capabilities, {
				textDocument = {
					formatting = { dynamicRegistration = false },
					rangeFormatting = { dynamicRegistration = false },
				},
			}),

			-- on_attach — вызывается после присоединения клиента к буферу
			on_attach = function(client, bufnr)
				-- Явно отключаем форматирование от LSP
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false

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
			local compile_db = vim.fn.find("compile_commands.json", {
				path = root,
				upward = true,
				type = "file",
			})[1]

			if compile_db then
				vim.notify(
					"compile_commands.json не найден! Соберите проект с -DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
					vim.log.levels.ERROR
				)
				return
			end

			vim.notify("Запуск clang-tidy...", vim.log.levels.INFO)

			local cmd = {
				"clang-tidy",
				"-p",
				vim.fn.fnamemodify(compile_db, ":h"),
				"--quiet",
				root .. "/**/*.cpp",
				root .. "/**/*.h",
				root .. "/**/*.hpp",
			}

			vim.system(cmd, {
				stdout = function(_, data)
					if data then
						vim.schedule(function()
							-- Парсим вывод clang-tidy и добавляем в quickfix
							local lines = vim.split(data, "\n", { plain = true })
							local qf_items = {}
							for _, line in ipairs(lines) do
								local file, lnum, col, msg = line:match("^(.-):(%d+):(%d+):%s*(.+)$")
								if file then
									table.insert(qf_items, {
										filename = file,
										lnum = tonumber(lnum),
										col = tonumber(col),
										text = msg,
									})
								end
							end
							if #qf_items > 0 then
								vim.fn.setqflist(qf_items, "a")
							end
						end)
					end
				end,
				on_exit = function(_, code)
					vim.schedule(function()
						if code == 0 then
							vim.notify(
								"Проверка завершена. Проблем не найдено!",
								vim.log.levels.INFO
							)
						else
							vim.cmd("copen")
							vim.notify(
								"Проверка завершена. Результаты в quickfix.",
								vim.log.levels.INFO
							)
						end
					end)
				end,
			})
		end, { desc = "Проверить все файлы проекта на ошибки" })

		-- Команда LspRestart для Neovim
		vim.api.nvim_create_user_command("LspRestart", function()
			local bufnr = vim.api.nvim_get_current_buf()
			local clients = vim.lsp.get_clients({ bufnr = bufnr })

			if not clients or vim.tbl_isempty(clients) then
				vim.notify("Нет активных LSP клиентов", vim.log.levels.WARN)
				return
			end

			for _, client in ipairs(clients) do
				client:stop(true)
			end

			vim.notify("LSP клиенты перезапущены", vim.log.levels.INFO)
			vim.cmd("edit " .. vim.fn.expand("%:p"))
		end, { desc = "Перезапустить LSP серверы" })
	end,
}

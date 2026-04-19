-- Автоформатирование кода (clang-format для C++ через mason)

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_format = "none" })
			end,
			mode = { "n", "v" },
			desc = "Format buffer",
		},
	},

	opts = {
		-- будет использоваться когда не найден ни один formatter для файла
		default_format_opts = {
			timeout_ms = 3000,
			async = true,
			quiet = false,
			lsp_format = "fallback",
		},

		-- асинхронное форматирование при сохранении
		format_after_save = function(bufnr)
			-- отключаем для больших файлов
			local line_count = vim.api.nvim_buf_line_count(bufnr)
			if line_count > 10000 then
				vim.notify(
					"Файл слишком большой, форматирование пропущено",
					vim.log.levels.WARN
				)
				return nil
			end

			-- Проверяем, есть ли форматтер
			local formatters = require("conform").list_formatters(bufnr)
			if #formatters == 0 then
				vim.notify(
					"Нет доступных форматтеров для этого файла",
					vim.log.levels.WARN
				)
				return nil
			end

			return {
				timeout_ms = 2000,
				lsp_format = "never",
			}
		end,

		formatters_by_ft = {
			lua = { "stylua" },

			-- Go
			go = { "goimports", "gofmt" },

			-- Python
			python = { "ruff_format" }, -- или {"isort", "black"}

			-- JavaScript / TypeScript / JSX / TSX
			javascript = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
			vue = { "prettierd", "prettier", stop_after_first = true },

			-- JSON / JSONC / YAML / Markdown
			json = { "prettierd", "prettier", stop_after_first = true },
			jsonc = { "prettierd", "prettier", stop_after_first = true },
			yaml = { "yamlfmt" },
			markdown = {},

			-- Shell / Docker / CMake
			sh = { "shfmt" },
			bash = { "shfmt" },
			zsh = { "shfmt" },
			dockerfile = { "hadolint" }, -- или просто "dockerfmt" если есть
			cmake = { "cmake_format" },

			-- C / C++
			c = { "clang_format" },
			h = { "clang_format" },
			cpp = { "clang_format" },
			hpp = { "clang_format" },
			cxx = { "clang_format" },
			hh = { "clang_format" },

			-- Rust
			rust = { "rustfmt" },

			-- другие языки
			sql = { "sqlfluff" },
			html = { "prettierd" },
			css = { "prettierd" },
		},

		-- Настройки конкретных форматтеров (очень полезно для clang-format)
		formatters = {
			clang_format = {
				-- Таймаут для больших C++ файлов
				timeout_ms = 2000,
				-- Явно указываем использовать файл конфигурации
				prepend_args = { "--style=file" },

				-- Условие запуска
				condition = function(ctx)
					-- Не форматируем если нет .clang-format в корне
					local root = vim.fn.findfile(".clang-format", ".;")
					if root == "" then
						vim.notify("Внимание: не найден .clang-format", vim.log.levels.WARN)
					end
					return true
				end,
			},
			stylua = {
				timeout_ms = 500,
			},
			shfmt = {
				prepend_args = { "-i", "4", "-ci" },
			},

			hadolint = {
				command = "dockerfile_lint",
			},
		},
	},
}

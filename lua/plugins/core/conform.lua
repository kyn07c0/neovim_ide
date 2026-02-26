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
			async = false,
		},

		-- асинхронное форматирование при сохранении
		format_after_save = function(bufnr)
			-- отключаем для больших файлов
			local line_count = vim.api.nvim_buf_line_count(bufnr)
			if line_count > 10000 then
				return nil
			end

			return {
				timeout_ms = 1000,
				lsp_format = "none",
				async = true,
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
			markdown = { "prettierd" },

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
				-- Используем файл проекта или быстрый fallback
				args = { "--style=LLVM" },
				-- Таймаут для больших C++ файлов
				timeout_ms = 2000,
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

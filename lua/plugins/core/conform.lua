-- Автоформатирование кода (clang-format для C++ через mason)

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = { "n", "v" },
			desc = "Format buffer (conform)",
		},
	},

	opts = {
		-- будет использоваться когда не найден ни один formatter для файла
		default_format_opts = {
			timeout_ms = 5000,
			async = false,
			quiet = false,
			lsp_format = "fallback",
		},

		format_on_save = {
			-- можно отключить для каких-то типов файлов
			timeout_ms = 2500,
			lsp_format = "fallback",
		},

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

			-- другие языки по желанию
			-- sql     = { "sqlfluff" },
			-- html    = { "prettierd" },
			-- css     = { "prettierd" },
		},

		-- Настройки конкретных форматтеров (очень полезно для clang-format)
		formatters = {
			clang_format = {
				-- По умолчанию ищет .clang-format в проекте → в родительских папках → в $HOME
				-- Если нужно явно указать стиль — раскомментируйте нужный вариант:

				-- 1. Использовать конкретный файл (редко нужно)
				-- prepend_args = { "--style=file:/путь/к/.clang-format" },

				-- 2. Явно указать fallback-стиль, если .clang-format не найден
				-- prepend_args = { "--fallback-style=LLVM" },          -- или Google, Chromium, Mozilla, WebKit
				-- prepend_args = { "--fallback-style=file" },          -- искать .clang-format

				-- 3. Самый популярный вариант — дать приоритет файлу проекта, а если нет — LLVM/Google
				prepend_args = {
					"--fallback-style=LLVM",
					"--style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Always, ColumnLimit: 0}",
				},
			},

			shfmt = {
				prepend_args = { "-i", "4", "-ci" },
			},

			hadolint = {
				command = "dockerfile_lint",
			},
		},
	},

	init = function()
		-- Отключаем LSP форматирование для C/C++
		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				local ft = vim.bo[args.buf].filetype

				if client and (ft == "cpp" or ft == "c" or ft:match("^h")) then
					client.server_capabilities.documentFormattingProvider = false
					client.server_capabilities.documentRangeFormattingProvider = false
					print("Отключено LSP форматирование для C/C++")
				end
			end,
		})

		-- Если вы хотите видеть, какие форматтеры будут запущены
		-- vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}

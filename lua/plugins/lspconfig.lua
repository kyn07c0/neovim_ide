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
				"--function-arg-placeholders",
				"--fallback-style=llvm",
				"--query-driver=/usr/bin/g++", -- компилятор
			},

			-- fallback-флаги, если нет compile_commands.json
			init_options = {
				compilationDatabasePath = "build", -- путь к compile_commands.json
				fallbackFlags = { "-std=c++23" },
				"-I${workspaceFolder}/include", -- базовые пути
				"-I${workspaceFolder}/src",
			},

			-- filetypes остаются те же
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },

			-- on_attach — вызывается после присоединения клиента к буферу
			on_attach = function(client, bufnr)
				-- omnifunc для Ctrl+X Ctrl+O
				vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

				local opts = { noremap = true, silent = true, buffer = bufnr }

				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
				vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
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

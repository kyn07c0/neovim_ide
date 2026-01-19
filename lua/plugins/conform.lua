-- conform.nvim — автоформатирование кода (clang-format для C++ через mason)
-- Лучше lsp-format, работает с инструментами вне LSP
return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	dependencies = { "williamboman/mason.nvim" },

	config = function()
		require("conform").setup({
			formatters_by_ft = {
				cpp = { "clang_format" },
				c = { "clang_format" },
				lua = { "stylua" },
			},

			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},

			formatters = {
				clang_format = {
					command = "clang-format",
					args = { "--style=llvm" },
				},
			},

			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
			log_level = vim.log.levels.ERROR,
		})

		-- Автоустановка clang-format (и stylua для lua)
		local mason_registry = require("mason-registry")
		mason_registry:on("package:install:success", function()
			vim.defer_fn(function()
				vim.cmd("Lazy sync")
			end, 100)
		end)

		mason_registry.get_package("clang-format"):install()
		mason_registry.get_package("stylua"):install()

		-- Клавиша для форматирования
		vim.keymap.set({ "n", "v" }, "<leader>cf", function()
			require("conform").format({ async = true, lsp_fallback = true })
		end, { desc = "Format buffer" })
	end,
}

-- Улучшенная настройка семантических токенов LSP

return {
	"neovim/nvim-lspconfig",
	optional = true,
	config = function(_, opts)
		-- Настройка переименования токенов для лучшей совместимости
		local function modify_semantic_tokens(client, bufnr)
			if not client.server_capabilities.semanticTokensProvider then
				return
			end

			-- Переопределяем токены для C++
			if client.name == "clangd" then
				local original_handler = vim.lsp.handlers["textDocument/semanticTokens/full"]

				vim.lsp.handlers["textDocument/semanticTokens/full"] = function(err, result, ctx, config)
					if err or not result then
						return original_handler(err, result, ctx, config)
					end

					-- Можно модифицировать токены здесь если нужно
					return original_handler(err, result, ctx, config)
				end
			end
		end

		-- Применяем ко всем клиентам
		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if client then
					modify_semantic_tokens(client, args.buf)
				end
			end,
		})
	end,
}

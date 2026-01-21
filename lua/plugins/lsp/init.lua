-- Плагины для работы с LSP

return {
	-- Конфигурация LSP-серверов
	require("plugins.lsp.lspconfig"),
	-- Менеджер для установки LSP-серверов и инструментов
	require("plugins.lsp.mason"),
}

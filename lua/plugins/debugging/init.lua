-- Плагины для отладки

return {
	-- Отладчик
	require("plugins.debugging.dap"),
	-- Виртуальный текст
	require("plugins.debugging.dap-virtual-text"),
	-- Интеграция с telescope
	require("plugins.debugging.telescope-dap"),
}

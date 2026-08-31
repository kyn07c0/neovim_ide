-- Агрегатор всех UI плагинов

return {
	-- Bufferline для вкладок
	require("plugins.ui.bufferline"),
	-- Статусная строка Lualine
	require("plugins.ui.lualine"),
	-- Folding с preview и treesitter-поддержкой
	require("plugins.ui.ufo"),
	-- Тема
	require("plugins.ui.theme"),
}

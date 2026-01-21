-- Плагины для навигации по файлам

return {
	-- Поиск символов, референсов, файлов, git
	require("plugins.navigation.telescope"),
	-- Кэширование результатов поиска
	require("plugins.navigation.telescope-frecency"),
	-- Файловый менеджер
	require("plugins.navigation.neo-tree"),
}

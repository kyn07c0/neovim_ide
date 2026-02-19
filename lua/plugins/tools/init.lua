-- Инструменты для разработки

return {
	-- Git знаки
	require("plugins.tools.gitsigns"),
	-- Открывает lazygit (мощный Git TUI)
	require("plugins.tools.lazygit"),
	-- Комментирование кода
	require("plugins.tools.comment"),
	-- Генератор документации
	require("plugins.tools.neogen"),
	-- Подсветка и поиск TODO, FIXME, NOTE, HACK и т.д.
	require("plugins.tools.todo-comments"),
	-- Анализ времени запуска Neovim
	require("plugins.tools.startuptime"),
	-- AI
	require("plugins.tools.codecompanion"),
}

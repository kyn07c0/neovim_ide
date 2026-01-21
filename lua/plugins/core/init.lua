-- Агрегатор всех core плагинов

return {
	-- Парсер для точной подсветки, folding и т.д.
	require("plugins.core.treesitter"),
	-- Для работы с блоками кода
	require("plugins.core.treesitter-textobjects"),
	-- Вертикальные линии для уровней отступов
	require("plugins.core.indent-blankline"),
	-- Автоформатирование кода
	require("plugins.core.conform"),
}

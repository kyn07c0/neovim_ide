-- Плагины для языков программирования

return {
	-- Для CMake
	require("plugins.languages.cmake-tools"),
	-- Улучшенная навигация по C++ коду
	require("plugins.languages.clangd-extensions"),
	-- Выравнивание текста
	require("plugins.languages.easy-align"),
}

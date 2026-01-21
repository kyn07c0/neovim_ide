-- vim-startuptime — анализ времени запуска Neovim (запуск с --startuptime)

return {
	"dstein64/vim-startuptime",
	cmd = "StartupTime",
	init = function()
		-- Оптимизация: не загружать плагин, если не нужен
		vim.g.startuptime_tries = 10 -- количество запусков для усреднения
	end,
}

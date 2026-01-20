vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Бутстрап Lazy.nvim (если не установлен, клонируем его автоматически)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- Используем стабильную ветку для надёжности
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Глобальные настройки Neovim
vim.opt.number = true -- Включаем нумерацию строк
vim.opt.relativenumber = true -- Относительная нумерация для удобства навигации
vim.opt.tabstop = 2 -- Размер табуляции
vim.opt.shiftwidth = 2 -- Сдвиг при отступах
vim.opt.expandtab = true -- Преобразование табов в пробелы
vim.g.mapleader = " " -- Лидер-ключ для кастомных комбинаций (пробел)
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:block,r-cr-o:hor20" -- Блочный курсор
vim.opt.equalalways = false
vim.opt.autochdir = false

-- Оптимизации для больших проектов
vim.o.swapfile = false -- отключить swap для производительности
vim.o.undofile = true -- включить persistent undo
vim.o.undolevels = 10000 -- большой history
vim.o.updatetime = 300 -- быстрее обновления CursorHold
vim.o.timeoutlen = 500 -- таймаут для последовательных клавиш

-- Настраиваем Lazy.nvim для загрузки плагинов из директории lua/plugins
require("lazy").setup("plugins")

-- Кэширование для Telescope
require("telescope").load_extension("frecency")

-- Инициализация всех core модулей

-- Загрузка основных настроек
require("core.options")
require("core.keymaps")
require("core.autocmds")
require("core.colors")

-- Установка лидеров
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Базовые настройки, которые не входят в options.lua
vim.opt.termguicolors = true -- Поддержка true colors
vim.opt.shell = "/bin/bash" -- Используем bash как оболочку

-- Отключение устаревших функций
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Отключение предупреждения о deprecated API
vim.g.lspconfig_nvim_0_11 = true

-- Настройка для более плавного скроллинга
vim.opt.smoothscroll = true

-- Проверка наличия termguicolors
if vim.fn.has("termguicolors") == 1 then
	vim.opt.termguicolors = true
end

print("✓ Core модули загружены")

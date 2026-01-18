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
vim.opt.number = true           -- Включаем нумерацию строк
vim.opt.relativenumber = true   -- Относительная нумерация для удобства навигации
vim.opt.tabstop = 4             -- Размер табуляции
vim.opt.shiftwidth = 4          -- Сдвиг при отступах
vim.opt.expandtab = true        -- Преобразование табов в пробелы
vim.g.mapleader = " "           -- Лидер-ключ для кастомных комбинаций (пробел)

-- Настраиваем Lazy.nvim для загрузки плагинов из директории lua/plugins
require("lazy").setup("plugins")

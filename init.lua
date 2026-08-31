-- Главный файл конфигурации Neovim

-- Загрузка ядра
require("core")

-- Инициализация lazy.nvim (менеджер плагинов)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Указываем Neovim, какие расширения файлов нужно сопоставлять
vim.filetype.add({
	extension = {
		j2 = "jinja2",
	},
})

-- Загрузка плагинов
require("lazy").setup("plugins", {
	change_detection = {
		-- Отключить проверку изменений
		enabled = false,
	},
})

-- Загрузка утилит
require("utils")

print("✓ Конфигурация Neovim загружена")

-- Основные настройки Neovim
local opt = vim.opt
local g = vim.g

---------- НОМЕРА СТРОК ----------
opt.number = true -- Абсолютные номера строк
opt.relativenumber = true -- Относительные номера строк
opt.signcolumn = "yes" -- Всегда показывать колонку знаков

---------- ТАБУЛЯЦИЯ И ОТСТУПЫ ----------
opt.tabstop = 4 -- Размер табуляции в пробелах
opt.shiftwidth = 4 -- Размер отступа для > и <
opt.softtabstop = 4 -- Количество пробелов при нажатии Tab
opt.expandtab = false -- Преобразовывать табы в пробелы
opt.smartindent = true -- Умные отступы
opt.smarttab = true -- Умные табы
opt.autoindent = true -- Автоматические отступы

---------- ПОИСК ----------
opt.ignorecase = true -- Игнорировать регистр при поиске
opt.smartcase = true -- Учитывать регистр если есть заглавные буквы
opt.hlsearch = true -- Подсвечивать результаты поиска
opt.incsearch = true -- Инкрементальный поиск
opt.wrapscan = true -- Искать циклически

---------- ИНТЕРФЕЙС ----------
opt.termguicolors = true -- True color поддержка
opt.cursorline = true -- Подсвечивать текущую строку
opt.laststatus = 3 -- Глобальная статусная строка
opt.cmdheight = 1 -- Высота командной строки
opt.pumheight = 10 -- Максимальная высота popup меню
opt.showtabline = 2 -- Всегда показывать вкладки
opt.splitright = true -- Новые окна слева
opt.splitbelow = true -- Новые окна снизу
opt.scrolloff = 8 -- Минимальное количество строк выше/ниже курсора
opt.sidescrolloff = 5 -- Минимальное количество колонок слева/справа от курсора
opt.equalalways = false -- Отключение автоматического выравнивания окон
opt.wrap = false -- Не переносить длинные строки

opt.lazyredraw = true -- Ленивая перерисовка
opt.redrawtime = 1500 -- Максимальное время перерисовки
opt.ttyfast = true -- Ускорение вывода в терминал
opt.sidescroll = 1 -- Минимальное количество строк для горизонтального скроллинга
opt.scrolljump = 5 -- Количество строк для прыжка при скроллинге

---------- МЫШЬ ----------
opt.mouse = "a" -- Включить мышь во всех режимах

---------- БУФЕР ОБМЕНА ----------
opt.clipboard = "unnamedplus" -- Использовать системный буфер обмена

---------- ИСТОРИЯ И ОТКАТ ----------
opt.undofile = true -- Сохранять историю изменений
opt.swapfile = false -- Не создавать swap файлы
opt.backup = false -- Не создавать backup файлы
opt.writebackup = false -- Не создавать backup перед записью
opt.updatetime = 300 -- Частота обновления (мс)
opt.timeoutlen = 500 -- Таймаут для маппингов (мс)

---------- АВТОЗАВЕРШЕНИЕ ----------
opt.completeopt = { "menuone", "noselect", "noinsert" }
opt.shortmess = "filnxtToOFWIcC"

---------- КОДИРОВКА ----------
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

---------- C++ СПЕЦИФИЧНЫЕ НАСТРОЙКИ ----------
opt.suffixesadd = { ".cpp", ".c", ".h", ".hpp", ".cc", ".cxx", ".hh" }
opt.includeexpr = "substitute(v:fname,'\\.','/','g')"
opt.path:append("**")
opt.path:append("/usr/include")
opt.path:append("/usr/local/include")

---------- ДИАГНОСТИКА ----------
vim.diagnostic.config({
	virtual_text = {
		prefix = "●",
		spacing = 4,
	},
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = "always",
		header = "",
		prefix = "",
	},
})

-- Знаки диагностики
local signs = { Error = "", Warn = "", Hint = "", Info = "" }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- Отключаем устаревшие функции
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1

-- Отключаем предупреждения о deprecated API
g.lspconfig_nvim_0_11 = true

print("✓ Настройки загружены")

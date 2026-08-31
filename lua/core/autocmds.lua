-- Автокоманды Neovim

-- Создаем группу для автокоманд
local autocmd_group = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- --- Настройка регистров для копирования и удаления ---

-- Копирование (yank) будет использовать системный буфер обмена ("+")
-- yy - копировать всю строку в системный буфер
-- y{motion} - копировать по движению в системный буфер
vim.api.nvim_set_keymap("n", "yy", '"+yy', { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "y", '"+y', { noremap = true, silent = true })

-- Удаление (delete) будет использовать стандартный регистр "" (который будет использован 'p' по умолчанию)
-- dd - удалять всю строку в регистр ""
-- d{motion} - удалять по движению в регистр ""
-- Например: d$ - удалять до конца строки в регистр ""
vim.api.nvim_set_keymap("n", "dd", "dd", { noremap = true, silent = true }) -- Удаление по умолчанию
vim.api.nvim_set_keymap("v", "d", "d", { noremap = true, silent = true }) -- Удаление по умолчанию

-- И чтобы 'p' по умолчанию вставлял из последнего использованного регистра (будь то "+" или "b")
-- Но если вы хотите, чтобы 'p' ВСЕГДА вставлял из системного буфера, тогда:
vim.api.nvim_set_keymap("n", "yy", '"+yy', { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "y", '"+y', { noremap = true, silent = true })

-- Удаление будет использовать регистр "b"
vim.api.nvim_set_keymap("n", "dd", '"bdd', { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "d", '"bd', { noremap = true, silent = true })

---------- АВТОМАТИЧЕСКОЕ СОХРАНЕНИЕ ----------

-- Автосохранение при потере фокуса
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
	group = autocmd_group,
	pattern = "*",
	command = "silent! wall",
	desc = "Автосохранение при потере фокуса",
})

-- Автосохранение через интервал времени (каждые 2 минуты)
vim.api.nvim_create_autocmd({ "CursorHold" }, {
	group = autocmd_group,
	pattern = "*",
	callback = function()
		if vim.bo.modified and not vim.bo.readonly and vim.fn.mode() == "n" then
			vim.cmd("silent! update")
		end
	end,
	desc = "Автосохранение через интервал",
})

---------- ВОССТАНОВЛЕНИЕ КУРСОРА ----------

-- Восстановление позиции курсора при открытии файла
vim.api.nvim_create_autocmd("BufReadPost", {
	group = autocmd_group,
	pattern = "*",
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
	desc = "Восстановление позиции курсора",
})

---------- ПРОВЕРКА ИЗМЕНЕНИЙ ФАЙЛОВ ----------

-- Перезагрузка файла при изменении вне Neovim
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	group = autocmd_group,
	pattern = "*",
	command = "if mode() != 'c' | checktime | endif",
	desc = "Проверка изменений файлов",
})

-- Уведомление при изменении файла
vim.api.nvim_create_autocmd("FileChangedShellPost", {
	group = autocmd_group,
	pattern = "*",
	command = "echohl WarningMsg | echo 'File changed on disk. Buffer reloaded.' | echohl None",
	desc = "Уведомление об изменении файла",
})

---------- СПЕЦИФИЧНЫЕ ДЛЯ ТИПОВ ФАЙЛОВ ----------

-- Настройки для CMake файлов
vim.api.nvim_create_autocmd("FileType", {
	group = autocmd_group,
	pattern = "cmake",
	callback = function()
		vim.bo.tabstop = 4
		vim.bo.shiftwidth = 4
		vim.bo.commentstring = "# %s"
	end,
	desc = "Настройки для CMake файлов",
})

-- Настройки для Markdown файлов
vim.api.nvim_create_autocmd("FileType", {
	group = autocmd_group,
	pattern = { "markdown", "md" },
	callback = function()
		vim.wo.wrap = true
		vim.wo.linebreak = true
		vim.wo.spell = true
		vim.bo.spelllang = "en_us,ru"
	end,
	desc = "Настройки для Markdown файлов",
})

-- Настройки для JSON файлов
vim.api.nvim_create_autocmd("FileType", {
	group = autocmd_group,
	pattern = "json",
	callback = function()
		vim.wo.conceallevel = 0
		vim.bo.expandtab = true
		vim.bo.tabstop = 4
		vim.bo.shiftwidth = 4
	end,
	desc = "Настройки для JSON файлов",
})

-- Настройки для YAML файлов
vim.api.nvim_create_autocmd("FileType", {
	group = autocmd_group,
	pattern = "yaml",
	callback = function()
		vim.bo.tabstop = 4
		vim.bo.shiftwidth = 4
		vim.bo.expandtab = true
	end,
	desc = "Настройки для YAML файлов",
})

-- Автоматическое закрытие скобок и кавычек для C/C++
vim.api.nvim_create_autocmd("FileType", {
	group = autocmd_group,
	pattern = { "cpp", "c", "h", "hpp" },
	callback = function()
		-- Настройки отступов для C/C++
		vim.bo.tabstop = 4
		vim.bo.shiftwidth = 4
		vim.bo.softtabstop = 4
		vim.bo.expandtab = false -- Используем табы, не пробелы
		vim.bo.textwidth = 0 -- Не ограничивать длину строки

		-- Отключаем форматирование от LSP если оно меняет отступы
		vim.b.disable_autoformat = false

		local current = vim.bo.matchpairs
		if not string.find(current, "<:>") then
			vim.bo.matchpairs = current .. ",<:>"
		end
	end,
	desc = "Добавление парных символов для C++",
})

---------- АВТООПРЕДЕЛЕНИЕ ПРОЕКТА ----------

-- Автоопределение CMake проекта
vim.api.nvim_create_autocmd("BufEnter", {
	group = autocmd_group,
	pattern = "*",
	callback = function()
		local cwd = vim.fn.getcwd()
		local cmake_file = cwd .. "/CMakeLists.txt"
		if vim.fn.filereadable(cmake_file) == 1 then
			vim.b.is_cmake_project = true
			vim.b.project_root = cwd

			-- Создаем симлинк compile_commands.json если его нет
			local compile_commands = cwd .. "/compile_commands.json"
			local build_compile_commands = cwd .. "/build/compile_commands.json"

			if vim.fn.filereadable(build_compile_commands) == 1 and vim.fn.filereadable(compile_commands) == 0 then
				os.execute("ln -sf " .. build_compile_commands .. " " .. compile_commands)
			end
		end
	end,
	desc = "Автоопределение CMake проекта",
})

---------- ОЧИСТКА БУФЕРОВ ----------

-- Автоматическое закрытие некоторых окон
vim.api.nvim_create_autocmd("BufEnter", {
	group = autocmd_group,
	pattern = "*",
	callback = function()
		-- Закрыть окно помощи если оно единственное
		if vim.bo.filetype == "help" and #vim.api.nvim_list_wins() == 1 then
			vim.cmd("quit")
		end
	end,
	desc = "Автоматическое закрытие окон",
})

-- Автоматическое создание директорий
vim.api.nvim_create_autocmd("BufWritePre", {
	group = autocmd_group,
	pattern = "*",
	callback = function(args)
		local dir = vim.fn.expand("<afile>:p:h")
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, "p")
		end
	end,
	desc = "Автоматическое создание директорий",
})

---------- ТЕРМИНАЛ ----------

-- Автоматический вход в режим вставки для терминала
vim.api.nvim_create_autocmd("TermOpen", {
	group = autocmd_group,
	pattern = "*",
	command = "startinsert",
	desc = "Автоматический вход в режим вставки для терминала",
})

-- Настройки терминала
vim.api.nvim_create_autocmd("TermOpen", {
	group = autocmd_group,
	pattern = "*",
	callback = function()
		vim.wo.number = false
		vim.wo.relativenumber = false
		vim.wo.signcolumn = "no"
		vim.wo.wrap = true
	end,
	desc = "Настройки терминала",
})

---------- КОММЕНТАРИИ ----------

-- Автоматическое продолжение комментариев
vim.api.nvim_create_autocmd("FileType", {
	group = autocmd_group,
	pattern = "*",
	callback = function()
		vim.bo.formatoptions = vim.bo.formatoptions:gsub("[cro]", "")
		vim.bo.formatoptions = vim.bo.formatoptions .. "cro"
	end,
	desc = "Настройки формата комментариев",
})

---------- УВЕДОМЛЕНИЯ ----------

-- Предупреждение о длинных строках
vim.api.nvim_create_autocmd("CursorMoved", {
	group = autocmd_group,
	pattern = "*",
	callback = function()
		local line = vim.api.nvim_get_current_line()
		if #line > 120 then
			vim.notify(
				"Строка слишком длинная (" .. #line .. " символов)",
				vim.log.levels.WARN
			)
		end
	end,
	desc = "Предупреждение о длинных строках",
})

------------- ОКНА -------------

vim.api.nvim_create_autocmd("WinResized", {
	group = autocmd_group,
	callback = function()
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.bo[buf].filetype == "neo-tree" then
				pcall(vim.api.nvim_win_set_width, win, 30)
			end
		end
	end,
	desc = "Фиксация ширины neo-tree при изменении layout",
})

-- Обновление neo-tree после git операций
vim.api.nvim_create_autocmd({ "FocusGained", "ShellCmdPost" }, {
	group = autocmd_group,
	pattern = "*",
	callback = function()
		-- Проверяем, загружен ли neo-tree
		local ok, manager = pcall(require, "neo-tree.sources.manager")
		if ok then
			vim.defer_fn(function()
				manager.refresh("filesystem")
			end, 100)
		end
	end,
	desc = "Обновление neo-tree после git операций",
})

print("✓ Автокоманды загружены")

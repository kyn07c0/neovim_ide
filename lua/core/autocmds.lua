-- Автокоманды Neovim

-- Создаем группу для автокоманд
local autocmd_group = vim.api.nvim_create_augroup("UserConfig", { clear = true })

---------- ФОРМАТИРОВАНИЕ ПРИ СОХРАНЕНИИ ----------

-- Форматирование C++ файлов при сохранении
vim.api.nvim_create_autocmd("BufWritePre", {
	group = autocmd_group,
	pattern = { "*.cpp", "*.c", "*.h", "*.hpp", "*.cc", "*.cxx" },
	callback = function()
		-- Форматируем через LSP, если доступно
		local clients = vim.lsp.get_clients()
		if #clients > 0 then
			vim.lsp.buf.format({ async = false })
		end
	end,
	desc = "Автоформатирование C++ файлов",
})

-- Форматирование Lua файлов при сохранении
vim.api.nvim_create_autocmd("BufWritePre", {
	group = autocmd_group,
	pattern = { "*.lua" },
	callback = function()
		local clients = vim.lsp.get_clients()
		if #clients > 0 then
			vim.lsp.buf.format({ async = false })
		end
	end,
	desc = "Автоформатирование Lua файлов",
})

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
		vim.bo.tabstop = 2
		vim.bo.shiftwidth = 2
		vim.bo.commentstring = "# %s"
	end,
	desc = "Настройки для CMake файлов",
})

-- Настройки для Markdown файлов
vim.api.nvim_create_autocmd("FileType", {
	group = autocmd_group,
	pattern = { "markdown", "md" },
	callback = function()
		vim.bo.wrap = true
		vim.bo.linebreak = true
		vim.bo.spell = true
		vim.bo.spelllang = "en_us,ru"
	end,
	desc = "Настройки для Markdown файлов",
})

-- Настройки для JSON файлов
vim.api.nvim_create_autocmd("FileType", {
	group = autocmd_group,
	pattern = "json",
	callback = function()
		vim.bo.conceallevel = 0
	end,
	desc = "Настройки для JSON файлов",
})

-- Настройки для YAML файлов
vim.api.nvim_create_autocmd("FileType", {
	group = autocmd_group,
	pattern = "yaml",
	callback = function()
		vim.bo.tabstop = 2
		vim.bo.shiftwidth = 2
	end,
	desc = "Настройки для YAML файлов",
})

-- Автоматическое закрытие скобок и кавычек для C/C++
vim.api.nvim_create_autocmd("FileType", {
	group = autocmd_group,
	pattern = { "cpp", "c", "h", "hpp" },
	callback = function()
		vim.bo.matchpairs:append("<:>")
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
vim.api.nvim_create_autocmd("BufEnter", {
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

print("✓ Автокоманды загружены")

-- Полезные функции общего назначения

local M = {}

---------- ОСНОВНЫЕ ФУНКЦИИ ----------

-- Безопасное выполнение require
function M.safe_require(module_name)
	local ok, module = pcall(require, module_name)
	if ok then
		return module
	else
		vim.notify("Не удалось загрузить модуль: " .. module_name, vim.log.levels.WARN)
		return nil
	end
end

-- Получить расширение файла
function M.get_file_extension(filename)
	return filename:match("^.+(%..+)$")
end

-- Проверить, является ли файл C/C++ файлом
function M.is_cpp_file(filename)
	local ext = M.get_file_extension(filename or vim.fn.expand("%"))
	local cpp_extensions = { ".cpp", ".c", ".h", ".hpp", ".cc", ".cxx", ".hh" }

	if ext then
		for _, cpp_ext in ipairs(cpp_extensions) do
			if ext == cpp_ext then
				return true
			end
		end
	end
	return false
end

-- Получить имя проекта из CMakeLists.txt
function M.get_project_name()
	local cwd = vim.fn.getcwd()
	local cmake_file = cwd .. "/CMakeLists.txt"

	if vim.fn.filereadable(cmake_file) == 1 then
		local file = io.open(cmake_file, "r")
		if file then
			for line in file:lines() do
				local project_name = line:match("project%(([%w_]+)%)")
				if project_name then
					file:close()
					return project_name
				end
			end
			file:close()
		end
	end
	return nil
end

-- Создать шаблон для нового файла
function M.create_file_template(filetype, filename)
	local templates = {
		cpp = [[#include <iostream>
#include <vector>
#include <string>

using namespace std;

int main() {
    cout << "Hello, C++!" << endl;
    return 0;
}]],

		h = function(name)
			local guard = name:upper():gsub("%.", "_") .. "_H"
			return string.format(
				[[
#ifndef %s
#define %s

// Объявления

#endif // %s
]],
				guard,
				guard,
				guard
			)
		end,

		cmake = [[cmake_minimum_required(VERSION 3.10)
project(NewProject)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(main main.cpp)]],

		lua = [[-- New Lua file

local M = {}

function M.setup()
  -- Configuration
end

return M]],
	}

	if templates[filetype] then
		if type(templates[filetype]) == "function" then
			return templates[filetype](filename)
		else
			return templates[filetype]
		end
	end

	return ""
end

-- Копировать текст в системный буфер
function M.copy_to_clipboard(text)
	vim.fn.setreg("+", text)
	vim.fn.setreg("*", text)
	vim.fn.setreg('"', text)
	return true
end

-- Показать уведомление с таймером
function M.show_notification(message, level, timeout)
	local notify = M.safe_require("notify")
	if notify then
		notify(message, level, { timeout = timeout or 3000 })
	else
		vim.notify(message, level)
	end
end

-- Получить относительный путь
function M.get_relative_path()
	local full_path = vim.fn.expand("%:p")
	local cwd = vim.fn.getcwd()

	if full_path:sub(1, #cwd) == cwd then
		return full_path:sub(#cwd + 2)
	end
	return full_path
end

-- Открыть файл в браузере (для ссылок)
function M.open_in_browser(url)
	local os_name = vim.loop.os_uname().sysname

	local commands = {
		Darwin = "open",
		Linux = "xdg-open",
		Windows = "start",
	}

	local cmd = commands[os_name]
	if cmd then
		vim.fn.jobstart({ cmd, url }, { detach = true })
		return true
	end
	return false
end

---------- РАБОТА С БУФЕРАМИ И ОКНАМИ ----------

-- Получить список открытых буферов
function M.get_open_buffers()
	local buffers = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
			local name = vim.api.nvim_buf_get_name(buf)
			if name ~= "" then
				table.insert(buffers, {
					id = buf,
					name = name,
					modified = vim.api.nvim_get_option_value("modified", { buf = buf }),
				})
			end
		end
	end
	return buffers
end

-- Закрыть все буферы кроме текущего
function M.close_other_buffers()
	local current_buf = vim.api.nvim_get_current_buf()
	local buffers = M.get_open_buffers()

	for _, buf in ipairs(buffers) do
		if buf.id ~= current_buf then
			vim.api.nvim_buf_delete(buf.id, { force = true })
		end
	end
end

-- Переключить между .cpp и .h файлами
function M.toggle_header_source()
	local current_file = vim.fn.expand("%:t")
	local base_name = current_file:match("(.+)%..+$")
	local ext = M.get_file_extension(current_file)

	if not base_name then
		return
	end

	local target_extensions = {}

	if ext == ".cpp" or ext == ".cc" or ext == ".cxx" then
		target_extensions = { ".h", ".hpp", ".hh" }
	elseif ext == ".h" or ext == ".hpp" or ext == ".hh" then
		target_extensions = { ".cpp", ".cc", ".cxx", ".c" }
	elseif ext == ".c" then
		target_extensions = { ".h" }
	end

	for _, target_ext in ipairs(target_extensions) do
		local target_file = base_name .. target_ext
		if vim.fn.filereadable(target_file) == 1 then
			vim.cmd("e " .. target_file)
			return true
		end
	end

	-- Если файл не найден, спросить создать ли его
	local create = vim.fn.input("Создать соответствующий файл? [y/N]: ")
	if create:lower() == "y" then
		local new_ext = target_extensions[1] or ".cpp"
		local new_file = base_name .. new_ext
		vim.cmd("e " .. new_file)

		if new_ext == ".h" or new_ext == ".hpp" or new_ext == ".hh" then
			local guard = base_name:upper():gsub("%.", "_") .. "_H"
			local header_template = string.format(
				[[
#ifndef %s
#define %s

// Объявления

#endif // %s
]],
				guard,
				guard,
				guard
			)

			vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(header_template, "\n"))
		end
		return true
	end

	return false
end

---------- РАБОТА С ПРОЕКТАМИ ----------

-- Поиск корня проекта
function M.find_project_root(patterns)
	patterns = patterns or { ".git", "CMakeLists.txt", "Makefile", "package.json" }
	local current_dir = vim.fn.expand("%:p:h")

	for i = 1, 20 do -- Ограничиваем глубину поиска
		for _, pattern in ipairs(patterns) do
			if vim.fn.glob(current_dir .. "/" .. pattern) ~= "" then
				return current_dir
			end
		end

		local parent = vim.fn.fnamemodify(current_dir, ":h")
		if parent == current_dir then
			break
		end
		current_dir = parent
	end

	return vim.fn.getcwd()
end

-- Запустить команду в терминале
function M.run_in_terminal(cmd, opts)
	opts = opts or {}
	local term_cmd = cmd

	-- Создаем окно терминала
	vim.cmd("vsplit")
	vim.cmd("terminal " .. term_cmd)

	-- Переходим в режим вставки
	vim.cmd("startinsert")

	-- Автоматически закрыть терминал после завершения команды
	if opts.auto_close then
		vim.api.nvim_create_autocmd("TermClose", {
			buffer = 0,
			callback = function()
				vim.cmd("bd!")
			end,
		})
	end
end

---------- ФОРМАТИРОВАНИЕ И ЛИНТИНГ ----------

-- Форматировать текущий файл
function M.format_file()
	local filetype = vim.bo.filetype

	-- Проверяем наличие LSP
	local clients = vim.lsp.get_clients()
	if #clients > 0 then
		vim.lsp.buf.format({ async = true })
		return true
	end

	-- Внешние инструменты форматирования
	local formatters = {
		cpp = "clang-format -i",
		c = "clang-format -i",
		lua = "stylua",
		python = "black",
		javascript = "prettier --write",
		typescript = "prettier --write",
		json = "jq .",
		yaml = "yamlfmt",
	}

	local formatter = formatters[filetype]
	if formatter then
		local filename = vim.fn.expand("%")
		local cmd = formatter .. " " .. vim.fn.shellescape(filename)
		vim.fn.system(cmd)
		vim.cmd("edit!") -- Перезагрузить файл
		return true
	end

	return false
end

-- Проверить синтаксис текущего файла
function M.check_syntax()
	local filetype = vim.bo.filetype

	local checkers = {
		cpp = "g++ -fsyntax-only -std=c++17",
		c = "gcc -fsyntax-only -std=c11",
		lua = "luacheck --no-color",
		python = "python -m py_compile",
		sh = "bash -n",
	}

	local checker = checkers[filetype]
	if checker then
		local filename = vim.fn.expand("%")
		local cmd = checker .. " " .. vim.fn.shellescape(filename)
		local output = vim.fn.system(cmd)

		if output ~= "" then
			vim.notify(output, vim.log.levels.ERROR)
			return false
		else
			vim.notify("Синтаксис корректный", vim.log.levels.INFO)
			return true
		end
	end

	return nil
end

---------- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ----------

-- Генерация UUID
function M.generate_uuid()
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	return string.gsub(template, "[xy]", function(c)
		local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format("%x", v)
	end)
end

-- Преобразовать snake_case в CamelCase
function M.snake_to_camel(str)
	return str:gsub("_(%w)", function(c)
		return c:upper()
	end):gsub("^(%w)", function(c)
		return c:upper()
	end)
end

-- Преобразовать CamelCase в snake_case
function M.camel_to_snake(str)
	return str:gsub("%u", function(c)
		return "_" .. c:lower()
	end):gsub("^_", "")
end

-- Вывести таблицу (для отладки)
function M.print_table(tbl, indent)
	if not indent then
		indent = 0
	end
	for k, v in pairs(tbl) do
		local formatting = string.rep("  ", indent) .. k .. ": "
		if type(v) == "table" then
			print(formatting)
			M.print_table(v, indent + 1)
		else
			print(formatting .. tostring(v))
		end
	end
end

-- Замер времени выполнения функции
function M.measure_time(func, ...)
	local start_time = vim.loop.hrtime()
	local result = { pcall(func, ...) }
	local end_time = vim.loop.hrtime()

	local success = result[1]
	local return_values = { unpack(result, 2) }

	local elapsed_ms = (end_time - start_time) / 1e6
	print(string.format("Время выполнения: %.2f мс", elapsed_ms))

	if success then
		return unpack(return_values)
	else
		error(return_values[1])
	end
end

-- Команда для пользователя: показать информацию о файле
vim.api.nvim_create_user_command("FileInfo", function()
	local info = {
		"Имя файла: " .. vim.fn.expand("%:t"),
		"Полный путь: " .. vim.fn.expand("%:p"),
		"Размер: " .. vim.fn.getfsize(vim.fn.expand("%:p")) .. " байт",
		"Тип: " .. vim.bo.filetype,
		"Кодировка: " .. vim.bo.fileencoding,
		"Формат: " .. vim.bo.fileformat,
	}

	vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
end, { desc = "Показать информацию о файле" })

return M

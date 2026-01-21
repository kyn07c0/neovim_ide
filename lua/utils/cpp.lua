-- Утилиты для работы с C++

local M = {}

function M.init()
	print("✓ C++ утилиты инициализированы")
end

-- Проверка наличия компилятора
function M.check_compiler()
	local compilers = {
		"g++",
		"clang++",
		"c++",
	}

	for _, compiler in ipairs(compilers) do
		if vim.fn.executable(compiler) == 1 then
			return compiler
		end
	end

	return nil
end

-- Получить рекомендуемые флаги компиляции
function M.get_compile_flags()
	local compiler = M.check_compiler() or "g++"
	local cpp_standard = "17"

	local base_flags = {
		"-std=c++" .. cpp_standard,
		"-Wall",
		"-Wextra",
		"-Wpedantic",
		"-Wshadow",
		"-Wconversion",
		"-Wsign-conversion",
		"-Werror",
		"-g",
		"-O0",
	}

	-- Дополнительные флаги для разных компиляторов
	local compiler_flags = {
		gcc = {
			"-fdiagnostics-color=always",
		},
		clang = {
			"-fcolor-diagnostics",
			"-ferror-limit=5",
		},
	}

	local flags = {}
	for _, flag in ipairs(base_flags) do
		table.insert(flags, flag)
	end

	local comp_name = compiler:match("([%w]+)%+%+") or compiler
	if compiler_flags[comp_name] then
		for _, flag in ipairs(compiler_flags[comp_name]) do
			table.insert(flags, flag)
		end
	end

	return flags, compiler
end

-- Создать тестовый C++ файл
function M.create_test_file(test_name)
	local template = string.format(
		[[
#include <iostream>
#include <cassert>
#include <vector>
#include <string>

// Тест: %s
void test_%s() {
    std::cout << "Running test: %s" << std::endl;

    // TODO: Добавить тесты
    assert(1 + 1 == 2 && "Basic math test");

    std::cout << "✓ Test passed: %s" << std::endl;
}

int main() {
    test_%s();
    std::cout << "\nAll tests passed!" << std::endl;
    return 0;
}
]],
		test_name,
		test_name,
		test_name,
		test_name,
		test_name
	)

	local filename = "test_" .. test_name .. ".cpp"
	vim.cmd("e " .. filename)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(template, "\n"))
end

-- Генерация геттеров и сеттеров для класса
function M.generate_getters_setters()
	local line = vim.api.nvim_get_current_line()
	local class_name = line:match("class%s+(%w+)")

	if not class_name then
		vim.notify("Не найден класс на текущей строке", vim.log.levels.ERROR)
		return
	end

	-- Получаем поля класса
	vim.cmd("normal! vip")
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")

	local fields = {}
	for i = start_line, end_line do
		local line_text = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
		local field = line_text:match("(%w+)%s*;")
		if field then
			local type = line_text:match("(%w+)%s+" .. field)
			if type then
				table.insert(fields, {
					name = field,
					type = type,
					capitalized = field:sub(1, 1):upper() .. field:sub(2),
				})
			end
		end
	end

	if #fields == 0 then
		vim.notify("Не найдены поля класса", vim.log.levels.WARN)
		return
	end

	-- Генерируем геттеры и сеттеры
	local result = {}
	for _, field in ipairs(fields) do
		-- Геттер
		table.insert(
			result,
			string.format("    %s get%s() const { return %s; }", field.type, field.capitalized, field.name)
		)

		-- Сеттер
		table.insert(
			result,
			string.format(
				"    void set%s(%s new_%s) { %s = new_%s; }",
				field.capitalized,
				field.type,
				field.name,
				field.name,
				field.name
			)
		)
	end

	-- Вставляем после класса
	vim.cmd("normal! o")
	vim.api.nvim_put(result, "l", true, true)
	vim.cmd("normal! ==") -- Форматируем отступы
end

-- Добавить include guard для заголовочного файла
function M.add_include_guard()
	local filename = vim.fn.expand("%:t")
	local guard = filename:upper():gsub("%.", "_")

	local guard_lines = {
		"#ifndef " .. guard,
		"#define " .. guard,
		"",
		"#endif // " .. guard,
	}

	-- Вставляем в начало и конец файла
	vim.api.nvim_buf_set_lines(0, 0, 0, false, { guard_lines[1], guard_lines[2], "" })
	vim.api.nvim_buf_set_lines(0, -1, -1, false, { "", guard_lines[4] })

	vim.notify("Include guard добавлен: " .. guard, vim.log.levels.INFO)
end

-- Создать минимальный класс
function M.create_minimal_class()
	local class_name = vim.fn.input("Имя класса: ")
	if class_name == "" then
		return
	end

	local header_name = class_name .. ".h"
	local source_name = class_name .. ".cpp"

	-- Создаем заголовочный файл
	local guard = class_name:upper() .. "_H"
	local header_content = string.format(
		[[
#ifndef %s
#define %s

class %s {
public:
    %s();
    ~%s();

    // TODO: Добавить методы

private:
    // TODO: Добавить поля
};

#endif // %s
]],
		guard,
		guard,
		class_name,
		class_name,
		class_name,
		guard
	)

	-- Создаем исходный файл
	local source_content = string.format(
		[[
#include "%s.h"

%s::%s() {
    // Конструктор
}

%s::~%s() {
    // Деструктор
}

// TODO: Реализовать методы
]],
		class_name,
		class_name,
		class_name,
		class_name,
		class_name
	)

	-- Сохраняем файлы
	vim.cmd("vsplit " .. header_name)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(header_content, "\n"))
	vim.cmd("w")

	vim.cmd("split " .. source_name)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(source_content, "\n"))
	vim.cmd("w")

	vim.notify(string.format("Класс %s создан", class_name), vim.log.levels.INFO)
end

-- Проверка стиля кода (Google/LLVM)
function M.check_code_style(style)
	style = style or "google"
	local filename = vim.fn.expand("%")

	if vim.fn.executable("clang-format") == 1 then
		local cmd = string.format("clang-format --style=%s --dry-run %s", style, filename)
		local output = vim.fn.system(cmd)

		if output == "" then
			vim.notify("Стиль кода соответствует " .. style, vim.log.levels.INFO)
		else
			vim.notify("Нарушения стиля:\n" .. output, vim.log.levels.WARN)
		end
	else
		vim.notify("clang-format не найден", vim.log.levels.ERROR)
	end
end

-- Пользовательские команды
vim.api.nvim_create_user_command("CppCreateTest", function(opts)
	M.create_test_file(opts.args)
end, {
	desc = "Создать тестовый C++ файл",
	nargs = 1,
})

vim.api.nvim_create_user_command("CppGenerateGettersSetters", M.generate_getters_setters, {
	desc = "Сгенерировать геттеры и сеттеры для класса",
})

vim.api.nvim_create_user_command("CppAddIncludeGuard", M.add_include_guard, {
	desc = "Добавить include guard в заголовочный файл",
})

vim.api.nvim_create_user_command("CppCreateClass", M.create_minimal_class, {
	desc = "Создать минимальный класс C++",
})

vim.api.nvim_create_user_command("CppCheckStyle", function(opts)
	M.check_code_style(opts.args)
end, {
	desc = "Проверить стиль кода C++",
	nargs = "?",
	complete = function()
		return { "google", "llvm", "microsoft", "webkit" }
	end,
})

return M

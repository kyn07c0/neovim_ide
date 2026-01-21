-- Утилиты для работы с CMake

local M = {}

function M.init()
	print("✓ CMake утилиты инициализированы")
end

-- Проверить, является ли текущий каталог CMake проектом
function M.is_cmake_project()
	local cwd = vim.fn.getcwd()
	local cmake_file = cwd .. "/CMakeLists.txt"
	return vim.fn.filereadable(cmake_file) == 1
end

-- Получить путь к CMakeLists.txt
function M.get_cmake_file_path()
	local cwd = vim.fn.getcwd()
	local cmake_file = cwd .. "/CMakeLists.txt"

	if vim.fn.filereadable(cmake_file) == 1 then
		return cmake_file
	end

	-- Поиск в родительских директориях
	local current_dir = cwd
	for i = 1, 10 do
		local parent = vim.fn.fnamemodify(current_dir, ":h")
		if parent == current_dir then
			break
		end
		current_dir = parent

		cmake_file = current_dir .. "/CMakeLists.txt"
		if vim.fn.filereadable(cmake_file) == 1 then
			return cmake_file
		end
	end

	return nil
end

-- Настроить CMake проект для LSP
function M.setup_cmake_project()
	local cwd = vim.fn.getcwd()
	local build_dir = cwd .. "/build"

	-- Проверяем, есть ли CMakeLists.txt
	if not M.is_cmake_project() then
		vim.notify("CMakeLists.txt не найден", vim.log.levels.ERROR)
		return false
	end

	-- Создаем build директорию если нет
	if vim.fn.isdirectory(build_dir) == 0 then
		vim.fn.mkdir(build_dir, "p")
		vim.notify("Создана директория build", vim.log.levels.INFO)
	end

	-- Генерируем проект
	vim.cmd("!cd " .. build_dir .. " && cmake .. -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -G Ninja")

	-- Ждем и создаем симлинк compile_commands.json
	vim.defer_fn(function()
		local compile_commands_build = build_dir .. "/compile_commands.json"
		local compile_commands_root = cwd .. "/compile_commands.json"

		if vim.fn.filereadable(compile_commands_build) == 1 then
			-- Удаляем старый симлинк если есть
			if vim.fn.filereadable(compile_commands_root) == 1 then
				os.remove(compile_commands_root)
			end

			-- Создаем симлинк
			local success = os.execute("ln -sf " .. compile_commands_build .. " " .. compile_commands_root)
			if success then
				vim.notify("Создан симлинк compile_commands.json", vim.log.levels.INFO)
			end
		else
			vim.notify("compile_commands.json не найден после генерации", vim.log.levels.WARN)
		end
	end, 2000)

	return true
end

-- Создать новый CMake проект
function M.create_cmake_project()
	local project_name = vim.fn.input("Имя проекта: ")
	if project_name == "" then
		return
	end

	local cmake_content = string.format(
		[[
cmake_minimum_required(VERSION 3.10)
project(%s VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Опции сборки
option(BUILD_TESTS "Build tests" ON)
option(BUILD_EXAMPLES "Build examples" OFF)

# Каталоги исходного кода
add_subdirectory(src)

# Тесты
if(BUILD_TESTS AND EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tests)
    enable_testing()
    add_subdirectory(tests)
endif()

# Примеры
if(BUILD_EXAMPLES AND EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/examples)
    add_subdirectory(examples)
endif()
]],
		project_name
	)

	local src_cmake = string.format(
		[[
# Основная библиотека
add_library(%s_lib STATIC
    lib.cpp
    lib.h
)

# Основной исполняемый файл
add_executable(%s_main
    main.cpp
)

# Связываем с библиотекой
target_link_libraries(%s_main PRIVATE %s_lib)

# Включаем директории
target_include_directories(%s_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(%s_main PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
]],
		project_name,
		project_name,
		project_name,
		project_name,
		project_name,
		project_name
	)

	local main_cpp = [[#include <iostream>
#include "lib.h"

int main() {
    std::cout << "Hello from " << PROJECT_NAME << "!" << std::endl;
    print_message();
    return 0;
}]]

	local lib_h = [[#pragma once

#include <string>

void print_message();]]

	local lib_cpp = string.format(
		[[
#include "lib.h"
#include <iostream>

void print_message() {
    std::cout << "This is library function from %s" << std::endl;
}]],
		project_name
	)

	-- Создаем структуру проекта
	local dirs = { "src", "include", "tests", "examples", "build", "docs" }
	for _, dir in ipairs(dirs) do
		vim.fn.mkdir(dir, "p")
	end

	-- Создаем файлы
	local files = {
		{ "CMakeLists.txt", cmake_content },
		{ "src/CMakeLists.txt", src_cmake },
		{ "src/main.cpp", main_cpp },
		{ "src/lib.h", lib_h },
		{ "src/lib.cpp", lib_cpp },
		{
			".gitignore",
			"build/*\n*.o\n*.so\n*.a\ncompile_commands.json\n.vscode/\n.idea/\n*.swp\n*.swo\n.DS_Store\nThumbs.db",
		},
		{
			"README.md",
			string.format(
				"# %s\n\nCMake проект создан через Neovim.\n\n## Сборка\n\n```bash\nmkdir build && cd build\ncmake .. -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -G Ninja\ncmake --build .\n```\n\n## Запуск\n\n```bash\n./build/src/%s_main\n```",
				project_name,
				project_name
			),
		},
		{
			"tests/CMakeLists.txt",
			string.format(
				[[
# Тесты
enable_testing()

add_executable(test_basic test_basic.cpp)
target_link_libraries(test_basic PRIVATE %s_lib)

add_test(NAME test_basic COMMAND test_basic)
]],
				project_name
			),
		},
		{
			"tests/test_basic.cpp",
			[[
#include <gtest/gtest.h>
#include "lib.h"

TEST(BasicTest, HelloWorld) {
    EXPECT_EQ(1, 1);
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}]],
		},
	}

	for _, file in ipairs(files) do
		local path, content = file[1], file[2]
		local f = io.open(path, "w")
		if f then
			f:write(content)
			f:close()
		end
	end

	vim.notify(string.format("CMake проект '%s' создан!", project_name), vim.log.levels.INFO)
end

-- Компиляция текущего файла
function M.compile_current_file()
	local filename = vim.fn.expand("%:t")
	local extension = filename:match("%.(%w+)$")

	if extension == "cpp" or extension == "cc" or extension == "cxx" then
		local output = filename:gsub("%.cpp$", ""):gsub("%.cc$", ""):gsub("%.cxx$", "")
		local cmd = string.format("g++ -std=c++17 -Wall -Wextra -o %s %s", output, filename)

		vim.cmd("vsplit | terminal " .. cmd)
		vim.cmd("startinsert")

		return true
	elseif extension == "c" then
		local output = filename:gsub("%.c$", "")
		local cmd = string.format("gcc -std=c11 -Wall -Wextra -o %s %s", output, filename)

		vim.cmd("vsplit | terminal " .. cmd)
		vim.cmd("startinsert")

		return true
	end

	vim.notify("Не C/C++ файл", vim.log.levels.WARN)
	return false
end

-- Запуск скомпилированного файла
function M.run_compiled_file()
	local filename = vim.fn.expand("%:t")
	local base_name = filename:match("(.+)%..+$")

	if base_name then
		if vim.fn.executable("./" .. base_name) == 1 then
			vim.cmd("vsplit | terminal ./" .. base_name)
			vim.cmd("startinsert")
			return true
		else
			vim.notify("Исполняемый файл не найден", vim.log.levels.ERROR)
		end
	end

	return false
end

-- Пользовательские команды
vim.api.nvim_create_user_command("CMakeSetup", M.setup_cmake_project, {
	desc = "Настроить CMake проект для LSP",
})

vim.api.nvim_create_user_command("CMakeCreateProject", M.create_cmake_project, {
	desc = "Создать новый CMake проект",
})

return M

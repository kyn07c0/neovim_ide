-- Утилиты

local M = {}

-- Безопасная загрузка модулей
function M.safe_require(module_name)
  local ok, module = pcall(require, module_name)
  if ok then
    return module
  end
  return nil
end

-- Загрузка всех модулей утилит
function M.load_utils()
  -- Основные функции
  local functions = M.safe_require("utils.functions")
  if functions then
    M.functions = functions
  end

  -- CMake утилиты
  local cmake = M.safe_require("utils.cmake")
  if cmake then
    M.cmake = cmake
    if M.cmake.init then
      M.cmake.init()
    end
  end

  -- C++ утилиты
  local cpp = M.safe_require("utils.cpp")
  if cpp then
    M.cpp = cpp
    if M.cpp.init then
      M.cpp.init()
    end
  end

  -- Git утилиты
  local git = M.safe_require("utils.git")
  if git then
    M.git = git
    if M.git.init then
      M.git.init()
    end
  end

  print("✓ Утилиты загружены")
end

-- Пример утилитной функции
function M.setup_cmake_project()
  if M.cmake and M.cmake.setup_cmake_project then
    return M.cmake.setup_cmake_project()
  else
    vim.notify("CMake утилиты не загружены", vim.log.levels.WARN)
    return false
  end
end

-- Инициализация
M.load_utils()

-- Команда для настройки проекта
vim.api.nvim_create_user_command("CMakeSetup", M.setup_cmake_project, {
  desc = "Настроить CMake проект"
})

return M

-- cmake-tools.nvim — удобная интеграция с CMake (build, run, debug)

return {
  "civitasv/cmake-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  ft = { "cmake" },  -- загружаем для CMake-файлов

  config = function()
    require("cmake-tools").setup({
      cmake_command = "cmake",
      cmake_build_directory = "build",  -- папка для сборки
      cmake_generate_options = { "-DCMAKE_BUILD_TYPE=Debug" },  -- дефолтные опции
      cmake_build_options = {},
      cmake_console_size = 10,  -- размер консоли снизу
      cmake_show_console = "always",
      cmake_dap_configuration = {  -- интеграция с dap
        name = "cpp",
        type = "codelldb",
        request = "launch",
        stopOnEntry = false,
        runInTerminal = true,
      },
    })

    -- Горячие клавиши
    vim.keymap.set("n", "<leader>cg", "<cmd>CMakeGenerate<cr>", { desc = "CMake Generate" })
    vim.keymap.set("n", "<leader>cb", "<cmd>CMakeBuild<cr>", { desc = "CMake Build" })
    vim.keymap.set("n", "<leader>cr", "<cmd>CMakeRun<cr>", { desc = "CMake Run" })
    vim.keymap.set("n", "<leader>cd", "<cmd>CMakeDebug<cr>", { desc = "CMake Debug" })
    vim.keymap.set("n", "<leader>cc", "<cmd>CMakeClean<cr>", { desc = "CMake Clean" })
    vim.keymap.set("n", "<leader>ct", "<cmd>CMakeSelectTarget<cr>", { desc = "Select Target" })
  end,
}

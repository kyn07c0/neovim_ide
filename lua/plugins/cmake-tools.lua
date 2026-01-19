-- cmake-tools.nvim — удобная интеграция с CMake (build, run, debug)

return {
  "civitasv/cmake-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  ft = { "cmake", "cpp", "c" },                 -- загружаем для CMake-файлов

  config = function()
    require("cmake-tools").setup({
      cmake_command = "cmake",
      cmake_build_directory = "build",          -- папка для сборки
      cmake_generate_options = {
          "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
          "-DCMAKE_BUILD_TYPE=Debug" 
      },
      cmake_build_options = {},
      cmake_console_size = 10,                  -- размер консоли снизу
      cmake_show_console = "always",
      cmake_dap_configuration = {               -- интеграция с dap
        name = "cpp",
        type = "codelldb",
        request = "launch",
        stopOnEntry = false,
        runInTerminal = true,
      },
      cmake_variants_message = {
        short = { show = true },
        long = { show = true, max_length = 40 }
      },
    })

    -- Автоматически обновлять compile_commands.json
    vim.api.nvim_create_autocmd("User", {
      pattern = "CMakeBuildFinished",
      callback = function()
        -- Копируем compile_commands.json в корень для clangd
        local root = vim.fn.getcwd()
        local source = root .. "/build/compile_commands.json"
        local target = root .. "/compile_commands.json"

        if vim.fn.filereadable(source) == 1 then
          os.execute("cp " .. source .. " " .. target)
          vim.notify("compile_commands.json обновлен", vim.log.levels.INFO)
        end
      end,
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

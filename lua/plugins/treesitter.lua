-- Парсер для точной подсветки, folding и т.д.

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",  -- обязательно, master заморожен
  version = false,
  build = ":TSUpdate",  -- обновляет парсеры при :Lazy sync / install
  lazy = false,

  config = function()
    -- Устанавливаем нужные парсеры один раз (асинхронно)
    -- Если уже установлены — пропустит
    require("nvim-treesitter").install({
      "cpp",
      "c",
      "cmake",
      "make",
      "lua",
      "vim",
      "vimdoc",
      "query",
      "markdown",
      "markdown_inline",
      "bash",
      "json",
      "yaml",
    })

    -- Автозапуск подсветки только после успешной установки парсера
    vim.api.nvim_create_autocmd({ "FileType" }, {
      pattern = { "c", "cpp", "lua", "vim", "markdown", "json", "yaml", "bash" },
      callback = function(ev)
        local ok, _ = pcall(vim.treesitter.start, ev.buf)
        if not ok then
          -- Если парсер ещё не готов — пробуем позже (через 100 мс)
          vim.defer_fn(function()
            pcall(vim.treesitter.start, ev.buf)
          end, 100)
        end
      end,
    })

    -- Folding для C/C++ (точный, на основе дерева)
    vim.api.nvim_create_autocmd({ "FileType" }, {
      pattern = { "c", "cpp" },
      callback = function()
        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
        vim.wo.foldenable = false  -- не сворачивать сразу при открытии
      end,
    })

    -- Indent на основе treesitter (экспериментально, но полезно)
    vim.api.nvim_create_autocmd({ "FileType" }, {
      pattern = { "c", "cpp", "lua" },
      callback = function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}

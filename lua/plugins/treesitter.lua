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
      -- Основные языки программирования
      "c",              -- Язык C
      "cpp",            -- Язык C++
      "cmake",          -- CMake
      "make",           -- Makefiles

      -- Системные языки
      "bash",           -- Shell скрипты
      "python",         -- Python
      "lua",            -- Lua (для конфигурации Neovim)
      "vim",            -- Vimscript
      "vimdoc",         -- Vim documentation

      -- Веб и разметка
      "html",
      "css",
      "javascript",
      "typescript",
      "tsx",
      "json",
      "yaml",
      "toml",
      "xml",

      -- Документация
      "markdown",
      "markdown_inline",
      "latex",

      -- Другие полезные языки
      "rust",
      "go",
      "java",
      "kotlin",
      "swift",
      "dockerfile",
      "gitignore",
      "gitcommit",
      "git_config",
      "git_rebase",

      -- Специальные парсеры
      "comment",        -- Комментарии
      "regex",          -- Регулярные выражения
      "query",          -- Treesitter queries 
    })



    require("nvim-treesitter.config").setup({
      -- ========================================
      -- ОСНОВНЫЕ НАСТРОЙКИ
      -- ========================================

      -- Автоматическая установка парсеров
      auto_install = true,

      -- Синхронная установка (может замедлить запуск)
      sync_install = false,

      -- Игнорировать установку для определенных языков
      ignore_install = { "phpdoc", "tree-sitter-phpdoc" },

      -- ========================================
      -- СПИСОК ПАРСЕРОВ (ОБЯЗАТЕЛЬНО ДЛЯ C/C++)
      -- ========================================
      ensure_installed = {
        -- Основные языки программирования
        "c",              -- Язык C
        "cpp",            -- Язык C++
        "cmake",          -- CMake
        "make",           -- Makefiles
        
        -- Системные языки
        "bash",           -- Shell скрипты
        "python",         -- Python
        "lua",            -- Lua (для конфигурации Neovim)
        "vim",            -- Vimscript
        "vimdoc",         -- Vim documentation
        
        -- Веб и разметка
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "json",
        "yaml",
        "toml",
        "xml",

        -- Документация
        "markdown",
        "markdown_inline",
        "latex",

        -- Другие полезные языки
        "rust",
        "go",
        "java",
        "kotlin",
        "swift",
        "dockerfile",
        "gitignore",
        "gitcommit",
        "git_config",
        "git_rebase",

        -- Специальные парсеры
        "comment",        -- Комментарии
        "regex",          -- Регулярные выражения
        "query",          -- Treesitter queries
      },

      -- ========================================
      -- ПОДСВЕТКА СИНТАКСИСА (ГЛАВНОЕ!)
      -- ========================================
      highlight = {
        enable = true,

        -- Использовать стандартную подсветку Vim как fallback
        additional_vim_regex_highlighting = {
          "markdown",     -- Для лучшей подсветки Markdown
          "c",            -- Дополнительная подсветка для C
          "cpp",          -- Дополнительная подсветка для C++
        },

        -- Отключить для больших файлов (оптимизация)
        disable = function(lang, buf)
          local max_filesize = 1024 * 1024 -- 1 MB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            vim.notify(string.format(
              "Treesitter отключен для файла %s (%.2f MB > 1 MB)",
              vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t"),
              stats.size / (1024 * 1024)
            ), vim.log.levels.WARN)
            return true
          end

          -- Отключить для определенных языков (опционально)
          local disabled_langs = { "latex", "tex" }
          return vim.tbl_contains(disabled_langs, lang)
        end,
      },

      -- ========================================
      -- АВТОМАТИЧЕСКИЕ ОТСТУПЫ
      -- ========================================
      indent = {
        enable = true,

        -- Отключить для языков с проблемными отступами
        disable = {
          "python",       -- Лучше использовать black/isort
          "yaml",         -- Чувствителен к пробелам
          "cpp",          -- Иногда ломает отступы в шаблонах
        },
      },

      -- ========================================
      -- ИНКРЕМЕНТАЛЬНЫЙ ВЫБОР
      -- ========================================
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "gnn",        -- Начать выделение
          node_incremental = "grn",      -- Расширить выделение
          scope_incremental = "grc",     -- Выделить область
          node_decremental = "grm",      -- Уменьшить выделение
        },
      },

      -- ========================================
      -- ТЕКСТОВЫЕ ОБЪЕКТЫ (ОЧЕНЬ ПОЛЕЗНО!)
      -- ========================================
      textobjects = {
        select = {
          enable = true,
          lookahead = true, -- Автоматически переходить вперед
          keymaps = {
            -- Для C/C++
            ["af"] = "@function.outer",  -- Вся функция
            ["if"] = "@function.inner",  -- Тело функции (без сигнатуры)
            ["ac"] = "@class.outer",     -- Весь класс
            ["ic"] = "@class.inner",     -- Тело класса
            ["ab"] = "@block.outer",     -- Блок кода { }
            ["ib"] = "@block.inner",     -- Содержимое блока

            -- Универсальные
            ["a/"] = "@comment.outer",   -- Комментарий
            ["i/"] = "@comment.inner",   -- Текст комментария
          },
        },

        move = {
          enable = true,
          set_jumps = true, -- Добавить в jumplist
          goto_next_start = {
            ["]m"] = "@function.outer",  -- Следующая функция
            ["]]"] = "@class.outer",     -- Следующий класс
          },
          goto_next_end = {
            ["]M"] = "@function.outer",
            ["]["] = "@class.outer",
          },
          goto_previous_start = {
            ["[m"] = "@function.outer",  -- Предыдущая функция
            ["[["] = "@class.outer",     -- Предыдущий класс
          },
          goto_previous_end = {
            ["[M"] = "@function.outer",
            ["[]"] = "@class.outer",
          },
        },

        swap = {
          enable = true,
          swap_next = {
            ["<leader>a"] = "@parameter.inner",  -- Поменять аргумент с следующим
          },
          swap_previous = {
            ["<leader>A"] = "@parameter.inner",  -- Поменять аргумент с предыдущим
          },
        },
      },

      -- ========================================
      -- ЦВЕТНЫЕ СКОБКИ (RAINBOW)
      -- ========================================
      rainbow = {
        enable = true,
        extended_mode = true, -- Также раскрашивать HTML теги
        max_file_lines = 3000, -- Не раскрашивать большие файлы
        colors = {
          "#cc241d", "#98971a", "#d79921", "#458588",
          "#b16286", "#689d6a", "#d65d0e",
        },
      },

      -- ========================================
      -- КОНТЕКСТ КОММЕНТАРИЕВ (ДЛЯ .H/.CPP)
      -- ========================================
      context_commentstring = {
        enable = true,
        enable_autocmd = false,

        -- Настройки для C/C++ файлов
        config = {
          c = "// %s",
          cpp = "// %s",
          glsl = "// %s",
        },
      },

      -- ========================================
      -- AUTOTAG (АВТОМАТИЧЕСКИЕ ТЕГИ)
      -- ========================================
      autotag = {
        enable = true,
        filetypes = {
          "html", "xml", "javascript", "typescript", "javascriptreact",
          "typescriptreact", "svelte", "vue", "tsx", "jsx", "markdown",
        },
      },

      -- ========================================
      -- MATCHUP (СОПОСТАВЛЕНИЕ СКОБОК И ТЕГОВ)
      -- ========================================
      matchup = {
        enable = true,
        include_match_words = true,
      },

      -- ========================================
      -- PLAYGROUND (ОТЛАДКА TREESITTER)
      -- ========================================
      playground = {
        enable = true,
        disable = {},
        updatetime = 25, -- Обновлять каждые 25 мс
        persist_queries = false,
        keybindings = {
          toggle_query_editor = "o",
          toggle_hl_groups = "i",
          toggle_injected_languages = "t",
          toggle_anonymous_nodes = "a",
          toggle_language_display = "I",
          focus_language = "f",
          unfocus_language = "F",
          update = "R",
          goto_node = "<cr>",
          show_help = "?",
        },
      },

      -- ========================================
      -- QUERY LINTER (ПРОВЕРКА QUERIES)
      -- ========================================
      query_linter = {
        enable = true,
        use_virtual_text = true,
        lint_events = { "BufWrite", "CursorHold" },
      },

      -- ========================================
      -- REFACTOR (РЕФАКТОРИНГ)
      -- ========================================
      refactor = {
        highlight_definitions = {
          enable = true,
          clear_on_cursor_move = true,
        },
        highlight_current_scope = {
          enable = false, -- Может быть навязчивым
        },
        smart_rename = {
          enable = true,
          keymaps = {
            smart_rename = "grr", -- Переименование с учетом контекста
          },
        },
        navigation = {
          enable = true,
          keymaps = {
            goto_definition = "gnd",  -- Перейти к определению
            list_definitions = "gnD", -- Список определений
            list_definitions_toc = "gO", -- Содержание
            goto_next_usage = "<a-*>",   -- Следующее использование
            goto_previous_usage = "<a-#>", -- Предыдущее использование
          },
        },
      },
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

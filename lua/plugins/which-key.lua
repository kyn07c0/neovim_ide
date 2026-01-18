-- which-key.nvim — показывает подсказки для горячих клавиш после нажатия <leader>

return {
  "folke/which-key.nvim",
  opts = {
    -- Настройки по умолчанию уже хорошие, но можно кастомизировать
    plugins = {
      marks = true,          -- показывает метки (ma → mA и т.д.)
      registers = true,      -- показывает содержимое регистров
      spelling = {
        enabled = true,
        suggestions = 20,
      },
      presets = {
        operators = true,
        motions = true,
        text_objects = true,
        windows = true,
        nav = true,
        z = true,
        g = true,
      },
    },

    -- Внешний вид окна
    win = {
      border = "rounded",          -- скруглённые углы
      --position = "bottom",         -- снизу экрана
      margin = { 1, 0, 1, 0 },     -- отступы
      padding = { 1, 2, 1, 2 },    -- внутренние отступы
      --winblend = 10,               -- прозрачность
    },

    -- Сортировка подсказок (по алфавиту, но можно изменить)
    sort = { "local", "order", "group", "alphanum", "mod" },

    -- Иконки (если у тебя есть nerdfonts)
    icons = {
      breadcrumb = "»",  -- разделитель в breadcrumb
      separator = "➜",   -- стрелка
      group = "+",       -- для групп
    },

    -- Показывать сразу после нажатия <leader> (без задержки)
    delay = function(ctx)
      return ctx.ctype == "mapping" and 0 or 500
    end,

    -- Показывать подсказки для всех <leader> mappings
    show_help = true,
    show_keys = true,
  },

  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)

    -- Регистрируем группы (чтобы красиво группировались в меню)
    wk.add({
      -- Основные группы
      { "<leader>f", group = "find / telescope" },
      { "<leader>l", group = "lsp" },
      { "<leader>d", group = "debug / dap" },
      { "<leader>c", group = "code / conform" },
      { "<leader>g", group = "git" },
      { "<leader>s", group = "surround / swap" },

      -- Конкретные примеры (добавляй свои по мере роста конфига)
      { "<leader>ff", desc = "Find files" },
      { "<leader>fg", desc = "Live grep" },
      { "<leader>fb", desc = "Buffers" },
      { "<leader>fs", desc = "Workspace symbols" },
      { "<leader>fd", desc = "Document symbols" },
      { "<leader>fr", desc = "References" },
      { "<leader>b",  desc = "Toggle breakpoint" },
      { "<leader>cf", desc = "Format buffer" },
      { "<leader>du", desc = "Toggle DAP UI" },
      { "<leader>dr", desc = "Toggle REPL" },
    })
  end,
}

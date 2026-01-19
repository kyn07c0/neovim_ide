-- Comment.nvim — мощное комментирование кода (лучше mini.comment по гибкости)

return {
  "numToStr/Comment.nvim",
  dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },  -- для treesitter-поддержки
  keys = {
    { "gc", mode = { "n", "v" } },  -- основной operator
    { "gcc", mode = "n" },          -- line comment
  },

  config = function()
    -- ts-context-commentstring нужен для правильного определения commentstring в смешанных файлах
    require("ts_context_commentstring").setup({
      enable_autocmd = false,
    })

    require("Comment").setup({
      -- Основные настройки
      padding = true,                     -- добавлять пробел после // или внутри /* */
      sticky = true,                      -- курсор остаётся на месте после toggle
      ignore = "^$",                      -- не комментировать пустые строки

      -- Treesitter-контекст (очень полезно для C++ с #if/#endif, шаблонами)
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),

      -- mappings (по умолчанию хорошие, но можно кастомизировать)
      mappings = {
        basic = true,
        extra = true,                     -- gco, gcA, gcO и т.д.
        extended = false,
      },

      -- Для C++: // для строк, /* */ для блоков
      toggler = {
        line = "gcc",
        block = "gbc",
      },
      opleader = {
        line = "gc",
        block = "gb",
      },
      extra = {
        above = "gcO",
        below = "gco",
        eol = "gcA",
      },
    })

    -- Интеграция с which-key (если используешь)
    -- require("which-key").add({
    --   { "gc", group = "comment" },
    --   { "gcc", desc = "Comment line" },
    --   { "gbc", desc = "Comment block" },
    --   { "gco", desc = "Comment below" },
    --   { "gcO", desc = "Comment above" },
    --   { "gcA", desc = "Comment to end of line" },
    -- })
  end,
}

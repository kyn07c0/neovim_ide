--Улучшение редактирования

return {
  "echasnovski/mini.nvim",
  version = false,  -- main ветка (стабильная и актуальная на 2026)
  config = function()
    -- 1. mini.pairs — автозакрытие скобок, <> для шаблонов C++
    require("mini.pairs").setup({
      -- Включаем в insert и command режимах
      modes = { insert = true, command = true, terminal = false },

      -- Специальные пары для C++ (шаблоны < >, комментарии /* */)
      mappings = {
        ["("] = { action = "open", pair = "()", neigh_pattern = "[^\\][%w%p%c%s]" },
        ["["] = { action = "open", pair = "[]", neigh_pattern = "[^\\][%w%p%c%s]" },
        ["{"] = { action = "open", pair = "{}", neigh_pattern = "[^\\][%w%p%c%s]" },
        ["<"] = { action = "open", pair = "<>", neigh_pattern = "[^\\][%w%p%c%s]" },  -- шаблоны!
        ['"'] = { action = "open", pair = '""' },
        ["'"] = { action = "open", pair = "''" },
        ["`"] = { action = "open", pair = "``" },
      },

      -- Автозакрытие для /* */ в комментариях (полезно)
      -- mini.pairs сам понимает контекст, но можно кастомизировать
    })

    -- 2. mini.comment — комментирование (gc для toggle)
    require("mini.comment").setup({
      -- Автоопределение commentstring для C/C++ (// и /* */)
      options = {
        custom_commentstring = nil,  -- использует filetype
        ignore_blank_line = false,
      },
      mappings = {
        comment = "gc",           -- normal/visual: toggle comment
        comment_line = "gcc",     -- comment current line
        textobject = "gc",        -- comment textobject
      },
    })

    -- 3. mini.surround — окружение текста (sa для add, sd для delete)
    require("mini.surround").setup({
      -- Кастомные delimiters для C++
      custom_surroundings = {
        ["("] = { input = { "(", ")" }, output = { left = "(", right = ")" } },
        ["{"] = { input = { "{", "}" }, output = { left = "{", right = "}" } },
        ["["] = { input = { "[", "]" }, output = { left = "[", right = "]" } },
        ["<"] = { input = { "<", ">" }, output = { left = "<", right = ">" } },  -- шаблоны
        ["b"] = { input = { "(", ")" }, output = { left = "( ", right = " )" } },  -- с пробелами
      },
      mappings = {
        add = "sa",           -- visual: sa + delimiter, normal: sa + motion + delimiter
        delete = "sd",        -- sd + delimiter
        find = "sf",          -- sf — найти следующий surrounding
        find_left = "sF",
        highlight = "sh",
        replace = "sr",
        update_n_lines = "sn",
      },
      n_lines = 500,  -- искать delimiters в пределах 500 строк
    })

    -- 4. mini.jump2d — быстрый прыжок по видимым строкам (по умолчанию f/F, но можно переопределить)
    require("mini.jump2d").setup({
      -- Используем подсветку для прыжков (очень быстро в большом коде)
      labels = "abcdefghijklmnopqrstuvwxyz",  -- метки для прыжков
      mappings = {
        start_jumping = "<leader>j",  -- или просто f / F если хочешь заменить
      },
    })

    -- 5. mini.align — интерактивное выравнивание (ga для start)
    require("mini.align").setup({
      -- mappings = { start = "ga" },
      -- options = { split_pattern = "" },  -- default ok
    })
  end,
}

-- nvim-treesitter-textobjects: для работы с блоками кода (af/if для функций, классов, if и т.д.)

return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  branch = "main",  -- обязательно для совместимости с nvim-treesitter main
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  event = { "BufReadPost", "BufNewFile" },

  opts = {  -- Lazy передаст в require("nvim-treesitter-textobjects").setup(opts)
    select = {
      enable = true,
      lookahead = true,  -- автоматически прыгать вперёд к следующему совпадению
      keymaps = {
        -- Стандартные для C++ (можно расширять)
        ["af"] = "@function.outer",     -- around function
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",        -- around class/namespace
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",    -- around argument
        ["ia"] = "@parameter.inner",
        ["al"] = "@loop.outer",         -- around loop (for/while)
        ["il"] = "@loop.inner",
        ["ai"] = "@conditional.outer",  -- around if/else
        ["ii"] = "@conditional.inner",
      },
      selection_modes = {
        ["@function.outer"] = "V",   -- line-wise для функций
        ["@class.outer"]    = "V",
      },
      include_surrounding_whitespace = true,
    },

    move = {
      enable = true,
      set_jumps = true,  -- добавлять в jumplist (Ctrl+O / Ctrl+I)
      goto_next_start = {
        ["]f"] = "@function.outer",
        ["]c"] = "@class.outer",
        ["]a"] = "@parameter.inner",
      },
      goto_next_end = {
        ["]F"] = "@function.outer",
        ["]C"] = "@class.outer",
      },
      goto_previous_start = {
        ["[f"] = "@function.outer",
        ["[c"] = "@class.outer",
        ["[a"] = "@parameter.inner",
      },
      goto_previous_end = {
        ["[F"] = "@function.outer",
        ["[C"] = "@class.outer",
      },
    },

    -- swap: поменять местами параметры/аргументы (очень полезно в C++)
    swap = {
      enable = true,
      swap_next = {
        ["<leader>sa"] = "@parameter.inner",  -- swap next argument
      },
      swap_previous = {
        ["<leader>sA"] = "@parameter.inner",
      },
    },
  },

  config = function(_, opts)
    require("nvim-treesitter-textobjects").setup(opts)

    -- Опционально: если хочешь repeatable с ; / , — используй nvim-next позже
    -- Пока оставляем базовые движения (]f [f и т.д.)
  end,
}

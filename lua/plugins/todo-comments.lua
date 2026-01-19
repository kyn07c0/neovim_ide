-- todo-comments.nvim — подсветка и поиск TODO, FIXME, NOTE, HACK и т.д.

return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufReadPost", "BufNewFile" },

  config = function()
    require("todo-comments").setup({
      signs = true,      -- показывать иконки в sign-column
      sign_priority = 8, -- приоритет знаков (чтобы не перекрывало gitsigns)
      keywords = {
        FIX = {
          icon = " ", -- иконка (можно убрать, если не нужны)
          color = "error",
          alt = { "FIXME", "BUG", "ISSUE" },
        },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = "󰈸 ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING" } },
        PERF = { icon = " ", alt = { "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "󰙨 ", color = "test", alt = { "TESTING" } },
      },

      -- Цвета (подстраиваются под твою тему, но можно явно задать)
      colors = {
        error   = { "DiagnosticError", "ErrorMsg", "#DC2626" },
        warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
        info    = { "DiagnosticInfo", "#2563EB" },
        hint    = { "DiagnosticHint", "#10B981" },
        default = { "Identifier", "#7C3AED" },
        test    = { "Identifier", "#FF00FF" },
      },

      -- Как искать: в комментариях, строках, docstring и т.д.
      highlight = {
        multiline = true,
        multiline_pattern = "^.",
        multiline_context = 10,
        before = "",
        keyword = "wide", -- или "fg", "bg"
        pattern = [[.*<(KEYWORDS)\s*:]],
        comments_only = true,
        max_line_len = 400,
        exclude = {},
      },

      -- Интеграция с Telescope (поиск всех todo по проекту)
      search = {
        command = "rg",
        args = {
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
        },
        pattern = [[\b(KEYWORDS):]],
      },
    })

    -- Горячие клавиши
    vim.keymap.set("n", "]t", function()
      require("todo-comments").jump_next()
    end, { desc = "Next TODO comment" })

    vim.keymap.set("n", "[t", function()
      require("todo-comments").jump_prev()
    end, { desc = "Prev TODO comment" })

    vim.keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Todo Telescope" })
    vim.keymap.set("n", "<leader>fT", "<cmd>TodoTelescope keywords=TODO,FIX,HACK<cr>", { desc = "Todo Telescope (filtered)" })
  end,
}

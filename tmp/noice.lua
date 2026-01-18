-- noice.nvim — современный UI для сообщений, cmdline, уведомлений и LSP progress

return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",           -- UI-компоненты
    "rcarriga/nvim-notify",           -- уведомления (опционально, но рекомендуется)
  },

  config = function()
    require("noice").setup({
      -- Основные модули
      cmdline = {
        view = "cmdline_popup",         -- красивый попап вместо строки снизу
        format = {
          cmdline = { pattern = "^:", icon = "" },
          search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
          search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
          filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
          lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*return%s*" }, icon = "", lang = "lua" },
          help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
          input = {},  -- используется по умолчанию
        },
      },

      messages = {
        enabled = true,
        view = "notify",
        view_error = "notify",
        view_warn = "notify",
        view_history = "messages",      -- :messages в попапе
        view_search = "virtualtext",    -- /поиск — мини-карта снизу
      },

      popupmenu = {
        enabled = true,
        backend = "nui",                -- nui для красивого меню
      },

      redirect = {
        view = "popup",
        filter = { event = "msg_show" },
      },

      -- Уведомления (notify)
      notify = {
        enabled = true,
        view = "notify",
      },

      lsp = {
        progress = {
          enabled = true,
          format = "lsp_progress",
          format_done = "lsp_progress_done",
          throttle = 1000 / 30,
          view = "mini",
        },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        hover = {
          enabled = true,
          silent = false,
          view = nil,
          opts = {},
        },
        signature = {
          enabled = true,
          auto_open = {
            enabled = true,
            trigger = true,
            luasnip = true,
            throttle = 50,
          },
          view = nil,
          opts = {},
        },
        message = {
          enabled = true,
          view = "notify",
          opts = {},
        },
        documentation = {
          view = "hover",
          opts = {
            lang = "markdown",
            replace = true,
            render = "plain",
            format = { "{message}" },
            win_options = { concealcursor = "n", conceallevel = 3 },
          },
        },
      },

      markdown = {
        hover = {
          ["|(%S-)|"] = vim.cmd.help,
          ["%[.-%]%((%S-)%)"] = require("noice.util").open,
        },
        highlights = {
          ["@lsp.type.namespace"] = { italic = true },
        },
      },

      health = {
        checker = true,
      },

      presets = {
        bottom_search = true,             -- cmdline внизу для поиска
        command_palette = true,           -- <C-c> для командной палитры
        long_message_to_split = true,     -- длинные сообщения в сплит
        inc_rename = false,               -- если используешь inc-rename
      },

      throttle = 1000 / 30,

      routes = {
        -- Скрываем некоторые скучные сообщения
        {
          filter = {
            event = "msg_show",
            kind = "",
            find = "written",
          },
          opts = { skip = true },
        },
        {
          filter = {
            event = "msg_show",
            kind = "search_count",
          },
          opts = { skip = true },
        },
      },

      views = {
        cmdline_popup = {
          position = {
            row = 5,
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winhighlight = { NormalFloat = "NormalFloat", FloatBorder = "NoiceCmdlinePopupBorder" },
          },
        },
        popupmenu = {
          relative = "editor",
          position = {
            row = 8,
            col = "50%",
          },
          size = {
            width = 60,
            height = 10,
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winhighlight = { NormalFloat = "NormalFloat", FloatBorder = "NoicePopupmenuBorder" },
          },
        },
      },

      status = {
        command = {
          event = "msg_showcmd",
        },
      },
    })

    -- Дополнительные клавиши
    vim.keymap.set({ "n", "i", "c" }, "<C-c>", function()
      if require("noice").cmdline.visible() then
        require("noice").cmdline.hide()
      else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, true, true), "n", true)
      end
    end, { desc = "Hide cmdline / Cancel" })

    -- :messages в красивом попапе
    vim.keymap.set("n", "<leader>m", "<cmd>Noice<CR>", { desc = "Noice messages" })
  end,
}

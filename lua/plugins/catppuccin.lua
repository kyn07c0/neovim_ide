-- catppuccin — очень красивая и современная тема (mocha — тёмная, мягкая)

return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,  -- загружаем раньше всех, чтобы тема применилась сразу
  lazy = false,

  config = function()
    require("catppuccin").setup({
      flavour = "mocha",  -- варианты: latte, frappe, macchiato, mocha
      background = {      -- адаптация под light/dark режим
        light = "latte",
        dark = "mocha",
      },

      transparent_background = false,  -- true если хочешь прозрачный фон (для терминала)
      show_end_of_buffer = false,
      term_colors = true,
      dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
      },

      no_italic = false,
      no_bold = false,

      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },

      color_overrides = {},
      custom_highlights = {},

      -- Интеграции с другими плагинами
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        telescope = true,
        treesitter = true,
        mason = true,
        harpoon = true,
        dap = {
          enabled = true,
          enable_ui = true,
        },
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { "italic" },
            hints = { "italic" },
            warnings = { "italic" },
            information = { "italic" },
          },
          underlines = {
            errors = { "underline" },
            hints = { "underline" },
            warnings = { "underline" },
            information = { "underline" },
          },
        },
        lsp_trouble = true,
        which_key = true,
        indent_blankline = {
          enabled = true,
          scope_color = "",
          colored_indent_levels = false,
        },
        dashboard = true,
        neogit = false,
        noice = true,
        notify = true,
        mini = true,
        bufferline = true,
        markdown = true,
        lazy = true,
        dap = true,
        dap_ui = true,
      },

      -- Кастомизация highlights (опционально)
      highlight_overrides = {
        mocha = function(colors)
          return {
            -- Пример: сделать комментарии более читаемыми
            Comment = { fg = colors.overlay0 },
            -- Или для C++: выделить namespace
            ["@lsp.type.namespace.cpp"] = { fg = colors.mauve, italic = true },
          }
        end,
      },
    })

    -- Активируем тему
    vim.cmd.colorscheme("catppuccin")

    -- Опционально: переключение между тёмной/светлой темой
    vim.keymap.set("n", "<leader>tl", function()
      vim.o.background = vim.o.background == "dark" and "light" or "dark"
      vim.cmd("colorscheme catppuccin")
    end, { desc = "Toggle light/dark" })
  end,
}

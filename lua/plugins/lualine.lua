-- lualine.nvim — красивый и кастомизируемый статуслайн

return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",  -- иконки (если нет — будет работать без них)
    "nvim-lua/lsp-status.nvim",     -- опционально, для лучшего LSP-статуса
  },
  event = "VeryLazy",  -- загружаем после открытия первого буфера

  config = function()
    local lualine = require("lualine")

    -- Кастомные компоненты (можно расширять)
    local function lsp_status()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      if #clients == 0 then return "" end

      local names = {}
      for _, client in ipairs(clients) do
        table.insert(names, client.name)
      end
      return " " .. table.concat(names, ", ")
    end

    local function diff_source()
      local gitsigns = vim.b.gitsigns_status_dict
      if not gitsigns then return "" end

      local added = gitsigns.added and gitsigns.added > 0 and "  " .. gitsigns.added or ""
      local changed = gitsigns.changed and gitsigns.changed > 0 and "  " .. gitsigns.changed or ""
      local removed = gitsigns.removed and gitsigns.removed > 0 and "  " .. gitsigns.removed or ""

      return added .. changed .. removed
    end

    lualine.setup({
      options = {
          icons_enabled = true,
          theme = "catppuccin", -- Используем тему catppuccin
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = true,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { {
            "filename",
            path = 1, -- Относительный путь
            symbols = {
              modified = "  ",
              readonly = "  ",
              unnamed = "  ",
              newfile = "  ",
            }
          } },
          lualine_x = {
            {
              "diagnostics",
              sources = { "nvim_diagnostic" },
              symbols = {
                error = " ",
                warn = " ",
                info = " ",
                hint = "󰌵 ",
              },
            },
            "encoding",
            "fileformat",
            "filetype"
          },
          lualine_y = { "progress" },
          lualine_z = { "location" }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = { "trouble", "fugitive", "nvim-dap-ui" }
    })
  end,
}

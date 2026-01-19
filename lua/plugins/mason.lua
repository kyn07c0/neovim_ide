-- Менеджер для установки LSP-серверов и инструментов

return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",  -- Интеграция с lspconfig для автоматической настройки
  },
  config = function()
    require("mason").setup({
      ui = {
        icons = {
          package_installed = "✓",  -- Иконка для установленных пакетов
          package_pending = "➜",    -- Иконка для ожидающих
          package_uninstalled = "✗" -- Иконка для неустановленных
        }
      }
    })

    require("mason-lspconfig").setup({
      ensure_installed = { "clangd", "lua_ls" },  -- Автоматически устанавливаем clangd для C++
      automatic_installation = true,    -- Автоустановка серверов при первом запуске
    })
  end,
}

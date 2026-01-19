-- Кэширование результатов поиска

return {
  "nvim-telescope/telescope-frecency.nvim",
  dependencies = { "nvim-telescope/telescope.nvim", "kkharji/sqlite.lua" },
  config = function()
    require("telescope").load_extension("frecency")
  end,
}

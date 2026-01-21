return {
	"nvim-telescope/telescope-dap.nvim",
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"mfussenegger/nvim-dap",
	},
	lazy = true, -- или event = "VeryLazy"
	config = function()
		-- Загружаем расширение после настройки telescope
		require("telescope").load_extension("dap")
	end,
}

-- Мощный Git TUI

return {
	"kdheepak/lazygit.nvim",
	-- Зависимости (обязательно)
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	cmd = {
		"LazyGit",
		"LazyGitCurrentFile",
		"LazyGitFilter",
		"LazyGitFilterCurrentFile",
	},
	-- Загружаем по клавише (очень удобно)
	keys = {
		{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit (project)" },
		{ "<leader>gf", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (current file)" },
	},
	-- Опционально: настройки
	opts = {
		-- Путь к lazygit (если не в PATH — укажите явно)
		-- lazygit_executable = "/usr/local/bin/lazygit",
		-- Открывать в текущей директории проекта
		--use_neovim_remote = true,  -- позволяет редактировать файлы прямо из lazygit через nvr
	},

	config = function(_, opts)
		-- Можно сохранить opts, если хотите (но не обязательно)
		vim.g.lazygit_floating_window_winblend = opts.floating_window_winblend or 0
		vim.g.lazygit_floating_window_scaling_factor = opts.floating_window_scaling_factor or 0.9

		-- Опционально: автообновление gitsigns после операций в lazygit
		vim.api.nvim_create_autocmd("User", {
			pattern = "LazyGitUpdate",
			callback = function()
				require("gitsigns").refresh()
			end,
		})
	end,
}

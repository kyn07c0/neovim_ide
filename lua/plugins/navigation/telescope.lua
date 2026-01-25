-- Поиск символов, референсов, файлов, git

return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x", -- стабильная ветка
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make", -- или "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build" если make не работает
		},
		"nvim-telescope/telescope-ui-select.nvim",
		"debugloop/telescope-undo.nvim", -- Для undo history
		"ahmedkhalf/project.nvim", -- Для управления проектами
	},

	config = function()
		local telescope = require("telescope")
		local builtin = require("telescope.builtin")
		local actions = require("telescope.actions")
		local themes = require("telescope.themes")

		telescope.setup({
			defaults = {
				mappings = {
					i = {
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
						["<C-c>"] = actions.close,
						["<C-u>"] = actions.preview_scrolling_up,
						["<C-d>"] = actions.preview_scrolling_down,
					},
					n = { ["q"] = actions.close },
				},

				layout_strategy = "horizontal",
				layout_config = {
					height = 0.90,
					width = 0.90,
					preview_cutoff = 120,
				},

				-- НЕ указываем file_sorter / generic_sorter вручную — fzf переопределит их сам
			},

			pickers = {
				live_grep = {
					additional_args = { "--hidden", "--glob=!.git/" },
				},
				find_files = {
					find_command = { "rg", "--files", "--hidden", "--glob=!.git/" },
				},
			},

			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true, -- переопределяет generic sorter
					override_file_sorter = true, -- переопределяет file sorter
					case_mode = "smart_case",
				},
				["ui-select"] = {
					themes.get_dropdown(),
				},
			},
		})

		-- Загружаем расширения (это активирует fzf-сортеры)
		telescope.load_extension("fzf")
		telescope.load_extension("ui-select")
		telescope.load_extension("undo")
		telescope.load_extension("projects")
		telescope.load_extension("frecency")

		-- Горячие клавиши (leader = space)
		--		local map = vim.keymap.set
		--		map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
		--		map("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
		--		map("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
		--		map("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
		--        map("n", "<leader>fu", "<cmd>Telescope undo<cr>", { desc = "Undo history" })
		--        map("n", "<leader>fp", "<cmd>Telescope projects<cr>", { desc = "Projects" })

		-- LSP (очень полезно в C++)
		--		map("n", "<leader>fs", builtin.lsp_dynamic_workspace_symbols, { desc = "Workspace symbols" })
		--		map("n", "<leader>fd", builtin.lsp_document_symbols, { desc = "Document symbols" })
		--		map("n", "<leader>flr", builtin.lsp_references, { desc = "References" })
		--		map("n", "<leader>fi", builtin.lsp_implementations, { desc = "Implementations" })

		-- Git
		--		map("n", "<leader>glc", builtin.git_commits, { desc = "Git commits" })
	end,
}

-- neo-tree.nvim — современный файловый менеджер

return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- иконки
		"MunifTanjim/nui.nvim",
		"3rd/image.nvim", -- preview изображений (опционально)
	},
	cmd = "Neotree",
	keys = {
		{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
		{ "<leader>o", "<cmd>Neotree focus<cr>", desc = "Focus Neo-tree" },
	},

	config = function()
		-- Настраиваем умное закрытие окон
		local function smart_close()
			local wins = vim.api.nvim_list_wins()
			local normal_wins = 0
			local neo_tree_wins = {}

			for _, w in ipairs(wins) do
				local buf = vim.api.nvim_win_get_buf(w)
				local ft = vim.api.nvim_buf_get_option(buf, "filetype")
				local buftype = vim.api.nvim_buf_get_option(buf, "buftype")

				if ft == "neo-tree" then
					table.insert(neo_tree_wins, w)
				elseif buftype == "" then -- нормальные буферы с файлами
					normal_wins = normal_wins + 1
				end
			end

			-- Если закрываем последнее нормальное окно
			if normal_wins <= 1 then
				-- Скрываем все окна neo-tree вместо закрытия
				for _, w in ipairs(neo_tree_wins) do
					vim.api.nvim_win_hide(w)
				end
			end
		end

		-- Автокоманда перед выходом
		vim.api.nvim_create_autocmd("QuitPre", {
			callback = smart_close,
		})

		require("neo-tree").setup({
			close_if_last_window = false,
			popup_border_style = "rounded",
			enable_git_status = true,
			enable_diagnostics = true,

			filesystem = {
				filtered_items = {
					visible = false,
					hide_dotfiles = true,
					hide_gitignored = true,
					hide_by_name = {
						"node_modules",
						".git",
					},
					never_show = { ".git" },
				},

				follow_current_file = {
					enabled = true,
					leave_dirs_open = true,
				},

				-- Использовать фиксированный корень
				bind_to_cwd = true,
				cwd_target = {
					sidebar = "tab",
				},

				-- Группировка пустых директорий
				group_empty_dirs = false,

				-- Не обновлять при изменении директории
				hijack_netrw_behavior = "open_default",

				window = {
					position = "left",
					width = 30,
					auto_expand_width = false,
					mapping_options = {
						noremap = true,
						nowait = true,
					},

					-- Сохранять состояние при переключении окон
					mappings = {
						["<space>"] = "none", -- отключаем дефолтное поведение space
						["<cr>"] = "open",
						["o"] = "open",
						["<esc>"] = "cancel",
						["P"] = { "toggle_preview", config = { use_float = true } },
						["l"] = "open",
						["h"] = "close_node",
						["s"] = "open_split",
						["v"] = "open_vsplit",
						["t"] = "open_tabnew",
						["a"] = { "add", config = { show_path = "none" } },
						["A"] = "add_directory",
						["d"] = "delete",
						["r"] = "rename",
						["y"] = "copy_to_clipboard",
						["x"] = "cut_to_clipboard",
						["p"] = "paste_from_clipboard",
						["c"] = "copy",
						["m"] = "move",
						["q"] = "close_window",
						["?"] = "show_help",
						["C"] = function(state)
							local node = state.tree:get_node()
							local path = node:get_id()
							vim.api.nvim_input(":e " .. path .. "/new_file.cpp<CR>")
						end,
					},
				},
			},

			buffers = {
				group_empty_dirs = true,
				show_unloaded = true,
				window = {
					mappings = {
						["bd"] = "buffer_delete",
						["<bs>"] = "navigate_up",
						["."] = "set_root",
					},
				},

				follow_current_file = {
					enabled = true,
					leave_dirs_open = true,
				},
			},

			git_status = {
				window = {
					position = "float",
					mappings = {
						["A"] = "git_add_all",
						["gu"] = "git_unstage_file",
						["ga"] = "git_add_file",
						["gr"] = "git_revert_file",
						["gc"] = "git_commit",
						["gp"] = "git_push",
						["gg"] = "git_commit_and_push",
					},
				},
			},

			-- Красивый вид
			default_component_configs = {
				container = { enable_character_fade = true },
				indent = {
					indent_size = 2,
					padding = 1,
					with_markers = true,
					last_indent_marker = "└",
					highlight = "NeoTreeIndentMarker",
					with_expanders = true,
					expander_collapsed = "",
					expander_expanded = "",
					expander_highlight = "NeoTreeExpander",
				},
				icon = {
					folder_closed = "",
					folder_open = "",
					folder_empty = "󰜌",
					default = "*",
					highlight = "NeoTreeFileIcon",
				},
				modified = { symbol = "[+]", highlight = "NeoTreeModified" },
				name = {
					trailing_slash = false,
					use_git_status_colors = true,
				},
				git_status = {
					symbols = {
						added = "✚",
						modified = "",
						deleted = "✖",
						renamed = "󰁕",
						untracked = "",
						ignored = "",
						unstaged = "󰄱",
						staged = "",
						conflict = "",
					},
				},
			},
		})
	end,
}

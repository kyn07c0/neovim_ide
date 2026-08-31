-- Файловый менеджер

return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- иконки
		"MunifTanjim/nui.nvim",
		"3rd/image.nvim", -- preview изображений (опционально)
	},
	cmd = { "Neotree", "NeoTreeShow", "NeoTreeFocus" },
	keys = {
		{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
		{ "<leader>o", "<cmd>Neotree focus<cr>", desc = "Focus Neo-tree" },
	},

	config = function()
		-- Троттлинг для refresh
		local refresh_timer = nil
		local function throttled_refresh()
			if refresh_timer then
				vim.fn.timer_stop(refresh_timer)
			end
			refresh_timer = vim.fn.timer_start(500, function()
				pcall(function()
					require("neo-tree.sources.manager").refresh("filesystem")
				end)
				refresh_timer = nil
			end)
		end

		require("neo-tree").setup({
			close_if_last_window = false,
			popup_border_style = "rounded",
			enable_git_status = true,
			enable_diagnostics = true,

			-- Настройки диагностики
			diagnostics = {
				enable = true,
				show_on_dirs = true,
				show_on_open_dirs = true,
				severity = {
					min = vim.diagnostic.severity.HINT,
					max = vim.diagnostic.severity.ERROR,
				},
				icons = {
					hint = "󰌵",
					info = "",
					warn = "",
					error = "",
				},
			},

			filesystem = {
				filtered_items = {
					visible = true,
					hide_dotfiles = false,
					hide_gitignored = false,
					hide_by_name = {
						"node_modules",
					},
					never_show = {},
				},

				follow_current_file = {
					enabled = true,
					leave_dirs_open = true,
					delay = 500,
				},

				-- Использовать фиксированный корень
				bind_to_cwd = false,

				-- Группировка пустых директорий
				group_empty_dirs = false,

				-- Не обновлять при изменении директории
				hijack_netrw_behavior = "open_default",

				use_libuv_file_watcher = true,

				window = {
					position = "left",
					width = 30, -- Постоянная ширина в 30 колонок
					auto_expand_width = false, -- Отключаем авто-расширение
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
					delay = 500,
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
				diagnostics = {
					symbols = {
						hint = "󰌵",
						info = "",
						warn = "",
						error = "",
					},
					highlight = "NeoTreeDiagnostic",
				},
			},

			window = {
				position = "left",
				width = 30,
				auto_expand_width = false,
				mappings = {
					["<space>"] = "none",
					["<cr>"] = "open",
					["o"] = "open",
				},
			},

			event_handlers = {
				{
					event = "neo_tree_buffer_enter",
					handler = function()
						local winid = vim.api.nvim_get_current_win()
						local bufnr = vim.api.nvim_win_get_buf(winid)
						if vim.bo[bufnr].filetype == "neo-tree" then
							pcall(vim.api.nvim_win_set_width, winid, 30)
						end
					end,
				},
				-- Обновление при изменении диагностики
				{
					event = "diagnostic_changed",
					handler = function()
						throttled_refresh()
					end,
				},
				{
					event = "before_render",
					handler = function()
						-- Проверяем, не закрывается ли другое окно
						local windows = vim.api.nvim_list_wins()
						local closing_windows = 0
						for _, win in ipairs(windows) do
							local config = vim.api.nvim_win_get_config(win)
							if type(config) == "table" and config.relative == "" then
								closing_windows = closing_windows + 1
							end
						end
						if closing_windows > 0 then
							vim.defer_fn(function()
								local manager = require("neo-tree.sources.manager")
								pcall(manager.show, "filesystem")
							end, 100)
							return { skip = true }
						end
					end,
				},
				-- Обновление при возвращении фокуса в nvim
				{
					event = "vim_resume", -- или "FocusGained"
					handler = function()
						require("neo-tree.sources.manager").refresh("filesystem")
					end,
				},
			},
		})

		vim.api.nvim_create_autocmd("BufWritePost", {
			pattern = "*.cpp,*.c,*.h,*.hpp,*.lua",
			callback = function()
				throttled_refresh()
			end,
		})
	end,
}

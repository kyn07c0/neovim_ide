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
	cmd = "Neotree",
	keys = {
		{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
		{ "<leader>o", "<cmd>Neotree focus<cr>", desc = "Focus Neo-tree" },
	},

	config = function()
		-- Получаем диагностику из LSP
		local get_diagnostics = function(bufnr)
			if not bufnr then
				return {}
			end

			local diagnostics = vim.diagnostic.get(bufnr)
			local result = {
				errors = 0,
				warnings = 0,
				info = 0,
				hints = 0,
			}

			for _, diag in ipairs(diagnostics) do
				if diag.severity == vim.diagnostic.severity.ERROR then
					result.errors = result.errors + 1
				elseif diag.severity == vim.diagnostic.severity.WARN then
					result.warnings = result.warnings + 1
				elseif diag.severity == vim.diagnostic.severity.INFO then
					result.info = result.info + 1
				elseif diag.severity == vim.diagnostic.severity.HINT then
					result.hints = result.hints + 1
				end
			end

			return result
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

			-- Кастомная функция для обновления диагностики
			diagnostic_updated = function()
				-- Перезагружаем neo-tree при обновлении диагностики
				require("neo-tree.sources.manager").refresh("filesystem")
			end,

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
				resize_timer_interval = 0,
				preserve_window_proportions = false,
			},

			event_handlers = {
				{
					event = "neo_tree_buffer_enter",
					handler = function()
						-- Получаем текущее окно neo-tree
						local winid = vim.api.nvim_get_current_win()
						-- Устанавливаем ширину в 30 колонок
						vim.api.nvim_win_set_width(winid, 30)
						-- При входе в neo-tree — фиксируем его слева
						vim.cmd("wincmd H")
					end,
				},
				-- Обновление при изменении диагностики
				{
					event = "diagnostic_changed",
					handler = function()
						-- Обновляем neo-tree при изменении диагностики
						vim.defer_fn(function()
							require("neo-tree.sources.manager").refresh("filesystem")
						end, 50)
					end,
				},
				-- Обновление при сохранении файла
				{
					event = "vim_buffer_enter",
					handler = function()
						vim.defer_fn(function()
							require("neo-tree.sources.manager").refresh("filesystem")
						end, 100)
					end,
				},
			},
		})

		-- Автоматическое обновление neo-tree при обновлении LSP диагностики
		vim.api.nvim_create_autocmd("DiagnosticChanged", {
			callback = function()
				-- Ждем немного, чтобы диагностика успела обновиться
				vim.defer_fn(function()
					-- Обновляем все открытые neo-tree
					for _, source in ipairs({ "filesystem", "buffers" }) do
						pcall(function()
							require("neo-tree.sources.manager").refresh(source)
						end)
					end
				end, 100)
			end,
		})

		-- Обновление при сохранении файла
		vim.api.nvim_create_autocmd("BufWritePost", {
			callback = function()
				vim.defer_fn(function()
					pcall(function()
						require("neo-tree.sources.manager").refresh("filesystem")
					end)
				end, 200) -- Даем время clangd на анализ
			end,
		})

		-- Обновление при выходе из режима вставки (где часто исправляются ошибки)
		vim.api.nvim_create_autocmd("InsertLeave", {
			callback = function()
				vim.defer_fn(function()
					pcall(function()
						require("neo-tree.sources.manager").refresh("filesystem")
					end)
				end, 300)
			end,
		})
	end,
}

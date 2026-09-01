-- Конфигурация темы

return {
	{
		"rebelot/kanagawa.nvim",
		lazy = false,
		priority = 1000,

		init = function()
			vim.opt.termguicolors = true
			vim.opt.background = "dark"

			if vim.env.NVIM_THEME then
				print("Используется тема из окружения: " .. vim.env.NVIM_THEME)
			end
		end,

		config = function()
			local theme_variant = os.getenv("NVIM_THEME") or "wave"

			require("kanagawa").setup({
				compile = true,
				undercurl = true,
				commentStyle = { italic = true },
				functionStyle = { bold = true },
				keywordStyle = { italic = true },
				statementStyle = { bold = true },
				typeStyle = {},
				transparent = false,
				dimInactive = true,
				terminalColors = false,
				theme = theme_variant,

				colors = {
					theme = {
						all = {
							ui = {
								bg_gutter = "none",
								float = {
									bg = "none",
									bg_border = "none",
								},
							},
						},
					},
				},

				overrides = function(colors)
					local theme = colors.theme
					local palette = colors.palette

					-- Цвет для разделителей (используется в нескольких местах)
					local separator_color = palette.autumnYellow

					return {
						-- ==========================================
						-- Базовые UI элементы
						-- ==========================================
						NormalFloat = { bg = "none" },
						NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },
						LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
						MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },

						-- Разделители и границы (исправлено: перенесено из vim.defer_fn)
						WinSeparator = { fg = separator_color },
						VertSplit = { fg = separator_color },
						FloatBorder = { fg = separator_color, bg = "none" },
						FloatTitle = { bg = "none" },
						TerminalBorder = { fg = theme.ui.bg_m3 },

						-- Меню автодополнения (Pmenu)
						Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
						PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
						PmenuSbar = { bg = theme.ui.bg_m1 },
						PmenuThumb = { bg = theme.ui.bg_p2 },

						-- ==========================================
						-- Диагностика (LSP)
						-- ==========================================
						DiagnosticVirtualTextError = { bg = "none" },
						DiagnosticVirtualTextWarn = { bg = "none" },
						DiagnosticVirtualTextInfo = { bg = "none" },
						DiagnosticVirtualTextHint = { bg = "none" },

						DiagnosticUnderlineError = { sp = palette.samuraiRed, undercurl = true },
						DiagnosticUnderlineWarn = { sp = palette.roninYellow, undercurl = true },
						DiagnosticUnderlineInfo = { sp = palette.dragonBlue, undercurl = true },
						DiagnosticUnderlineHint = { sp = palette.waveAqua1, undercurl = true },

						-- ==========================================
						-- Telescope
						-- ==========================================
						TelescopeTitle = { fg = theme.ui.special, bold = true },
						TelescopePromptNormal = { bg = theme.ui.bg_p1 },
						TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
						TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
						TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
						TelescopePreviewNormal = { bg = theme.ui.bg_dim },
						TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },

						-- ==========================================
						-- NeoTree
						-- ==========================================
						NeoTreeNormal = { bg = theme.ui.bg },
						NeoTreeNormalNC = { bg = theme.ui.bg },
						NeoTreeFloatBorder = { fg = separator_color, bg = theme.ui.bg_m1 },

						-- ==========================================
						-- BufferLine
						-- ==========================================
						BufferLineFill = { bg = theme.ui.bg_m3 },
						BufferLineBackground = { bg = theme.ui.bg_m2, fg = theme.ui.fg_dim },
						BufferLineBufferSelected = { bg = theme.ui.bg, fg = theme.ui.fg, bold = true },
						BufferLineBufferVisible = { bg = theme.ui.bg_m1, fg = theme.ui.fg },
						BufferLineSeparator = { fg = theme.ui.bg_m3, bg = theme.ui.bg },
						BufferLineSeparatorSelected = { bg = theme.ui.bg, fg = theme.ui.bg_m3 },
						BufferLineSeparatorVisible = { bg = theme.ui.bg, fg = theme.ui.bg_m3 },
						BufferLineIndicatorSelected = { fg = theme.ui.special },

						-- ==========================================
						-- Lualine
						-- ==========================================
						lualine_a_normal = { bg = theme.ui.special, fg = theme.ui.bg },
						lualine_b_normal = { bg = theme.ui.bg_m3, fg = theme.ui.fg },
						lualine_c_normal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },

						-- ==========================================
						-- nvim-cmp (Автодополнение)
						-- ==========================================
						CmpItemAbbr = { fg = theme.ui.fg },
						CmpItemAbbrMatch = { fg = theme.ui.special, bold = true },
						CmpItemKind = { fg = palette.carpYellow },
						CmpItemMenu = { fg = palette.fujiGray },

						-- ==========================================
						-- Diff (Git)
						-- ==========================================
						DiffAdd = { bg = palette.winterGreen },
						DiffChange = { bg = palette.winterYellow },
						DiffDelete = { bg = palette.winterRed },
						DiffText = { bg = palette.winterBlue },

						-- ==========================================
						-- Treesitter (Общие группы)
						-- ==========================================
						["@variable"] = { fg = theme.ui.fg },
						["@variable.builtin"] = { fg = palette.roninYellow, italic = true },
						["@variable.parameter"] = { fg = palette.peachRed, italic = true },
						["@variable.member"] = { fg = palette.boatYellow2 },

						["@function"] = { fg = palette.carpYellow, bold = true },
						["@function.builtin"] = { fg = palette.springGreen, italic = true },
						["@function.call"] = { fg = palette.carpYellow },
						["@function.method"] = { fg = palette.crystalBlue },
						["@function.method.call"] = { fg = palette.crystalBlue },

						["@constructor"] = { fg = palette.springBlue, bold = true },

						["@parameter"] = { fg = palette.peachRed, italic = true },
						["@field"] = { fg = palette.boatYellow2 },
						["@property"] = { fg = palette.carpYellow, bold = true },

						["@conditional"] = { fg = palette.autumnRed, bold = true },
						["@repeat"] = { fg = palette.autumnRed, bold = true },
						["@label"] = { fg = palette.boatYellow2 },
						["@keyword"] = { fg = palette.autumnRed, bold = true },
						["@keyword.function"] = { fg = palette.springBlue, italic = true },
						["@keyword.operator"] = { fg = palette.autumnRed },
						["@keyword.return"] = { fg = palette.autumnRed, bold = true },

						["@operator"] = { fg = palette.springBlue },
						["@exception"] = { fg = palette.autumnRed, bold = true },

						["@type"] = { fg = palette.springGreen, bold = true },
						["@type.builtin"] = { fg = palette.springGreen, italic = true },
						["@type.definition"] = { fg = palette.springGreen, bold = true },
						["@structure"] = { fg = palette.waveAqua2, bold = true },
						["@namespace"] = { fg = palette.fujiGray, italic = true },
						["@include"] = { fg = palette.springBlue, italic = true },
						["@annotation"] = { fg = palette.fujiGray },
						["@macro"] = { fg = palette.autumnYellow, italic = true },

						["@constant"] = { fg = palette.springViolet2, bold = true },
						["@constant.builtin"] = { fg = palette.springViolet2, italic = true },
						["@constant.macro"] = { fg = palette.autumnYellow },

						["@string"] = { fg = palette.waveGreen },
						["@string.regex"] = { fg = palette.waveAqua1 },
						["@string.escape"] = { fg = palette.springBlue, bold = true },
						["@string.special"] = { fg = palette.springBlue },

						["@number"] = { fg = palette.waveViolet },
						["@number.float"] = { fg = palette.waveViolet },
						["@boolean"] = { fg = palette.autumnRed, bold = true },

						["@comment"] = { fg = palette.fujiGray, italic = true },
						["@comment.todo"] = { fg = palette.winterGreen, bold = true, italic = true },
						["@comment.note"] = { fg = palette.winterBlue, bold = true, italic = true },
						["@comment.warning"] = { fg = palette.winterYellow, bold = true, italic = true },
						["@comment.error"] = { fg = palette.winterRed, bold = true, italic = true },

						["@text.danger"] = { bg = palette.winterRed, fg = palette.fujiWhite, bold = true },
						["@text.warning"] = { bg = palette.winterYellow, fg = palette.fujiWhite, bold = true },
						["@text.note"] = { bg = palette.winterBlue, fg = palette.fujiWhite, bold = true },
						["@text.todo"] = { bg = palette.winterGreen, fg = palette.fujiWhite, bold = true },
						["@text.uri"] = { fg = palette.springBlue, underline = true },
						["@text.literal"] = { fg = palette.waveGreen, italic = true },
						["@text.reference"] = { fg = palette.springViolet2, bold = true },
						["@text.title"] = { fg = palette.carpYellow, bold = true },
						["@text.emphasis"] = { fg = theme.ui.fg, italic = true },
						["@text.strong"] = { fg = theme.ui.fg, bold = true },
						["@text.strike"] = { fg = palette.fujiGray, strikethrough = true },

						["@diff.plus"] = { fg = palette.winterGreen },
						["@diff.minus"] = { fg = palette.winterRed },
						["@diff.delta"] = { fg = palette.winterYellow },

						["@tag"] = { fg = palette.autumnRed },
						["@tag.attribute"] = { fg = palette.springViolet2, italic = true },
						["@tag.delimiter"] = { fg = palette.springBlue },

						["@markup.strong"] = { bold = true },
						["@markup.italic"] = { italic = true },
						["@markup.strikethrough"] = { strikethrough = true },
						["@markup.underline"] = { underline = true },
						["@markup.heading"] = { fg = palette.carpYellow, bold = true },
						["@markup.quote"] = { fg = palette.fujiGray, italic = true },
						["@markup.math"] = { fg = palette.springBlue },
						["@markup.environment"] = { fg = palette.springGreen },
					}
				end,

				background = {
					dark = "wave",
					light = "lotus",
				},
			})

			vim.cmd.colorscheme("kanagawa-" .. theme_variant)

			-- Простые команды для смены темы
			vim.api.nvim_create_user_command("KanagawaWave", function()
				vim.cmd.colorscheme("kanagawa-wave")
				vim.notify("Тема установлена: Kanagawa Wave", vim.log.levels.INFO)
			end, { desc = "Установить тему Kanagawa Wave" })

			vim.api.nvim_create_user_command("KanagawaDragon", function()
				vim.cmd.colorscheme("kanagawa-dragon")
				vim.notify("Тема установлена: Kanagawa Dragon", vim.log.levels.INFO)
			end, { desc = "Установить тему Kanagawa Dragon" })

			vim.api.nvim_create_user_command("KanagawaLotus", function()
				vim.cmd.colorscheme("kanagawa-lotus")
				vim.notify("Тема установлена: Kanagawa Lotus", vim.log.levels.INFO)
			end, { desc = "Установить тему Kanagawa Lotus" })

			vim.api.nvim_create_user_command("KanagawaTransparent", function()
				local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })

				if normal_hl.bg == nil then
					-- Восстанавливаем цвета темы
					vim.api.nvim_set_hl(0, "Normal", { bg = "#1F1F28" })
					vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1e1e2e" })
					vim.notify("Прозрачность выключена", vim.log.levels.INFO)
				else
					-- Включаем прозрачность
					vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
					vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
					vim.notify("Прозрачность включена", vim.log.levels.INFO)
				end
			end, { desc = "Переключить прозрачный фон" })

			print("✓ Тема Kanagawa загружена: " .. theme_variant)
		end,
	},
}

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

					return {
						Normal = { bg = "none" },
						NormalFloat = { bg = "none" },
						FloatBorder = { bg = "none" },
						FloatTitle = { bg = "none" },
						NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },
						LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
						MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
						Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
						PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
						PmenuSbar = { bg = theme.ui.bg_m1 },
						PmenuThumb = { bg = theme.ui.bg_p2 },

						DiagnosticVirtualTextError = { bg = "none" },
						DiagnosticVirtualTextWarn = { bg = "none" },
						DiagnosticVirtualTextInfo = { bg = "none" },
						DiagnosticVirtualTextHint = { bg = "none" },

						DiagnosticUnderlineError = { sp = palette.samuraiRed, undercurl = true },
						DiagnosticUnderlineWarn = { sp = palette.roninYellow, undercurl = true },
						DiagnosticUnderlineInfo = { sp = palette.dragonBlue, undercurl = true },
						DiagnosticUnderlineHint = { sp = palette.waveAqua1, undercurl = true },

						TelescopeTitle = { fg = theme.ui.special, bold = true },
						TelescopePromptNormal = { bg = theme.ui.bg_p1 },
						TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
						TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
						TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
						TelescopePreviewNormal = { bg = theme.ui.bg_dim },
						TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },

						NeoTreeNormal = { bg = theme.ui.bg_m3 },
						NeoTreeNormalNC = { bg = theme.ui.bg_m3 },
						NeoTreeFloatBorder = { fg = theme.ui.float.fg_border, bg = theme.ui.bg_m3 },

						BufferLineFill = { bg = theme.ui.bg_m3 },
						BufferLineBackground = { bg = theme.ui.bg_m2, fg = theme.ui.fg_dim },
						BufferLineBufferSelected = { bg = theme.ui.bg, fg = theme.ui.fg, bold = true },
						BufferLineBufferVisible = { bg = theme.ui.bg_m1, fg = theme.ui.fg },
						BufferLineSeparator = { fg = theme.ui.bg_m3, bg = theme.ui.bg },
						BufferLineSeparatorSelected = { bg = theme.ui.bg, fg = theme.ui.bg_m3 },
						BufferLineSeparatorVisible = { bg = theme.ui.bg, fg = theme.ui.bg_m3 },
						BufferLineIndicatorSelected = { fg = theme.ui.special },

						lualine_a_normal = { bg = theme.ui.special, fg = theme.ui.bg },
						lualine_b_normal = { bg = theme.ui.bg_m3, fg = theme.ui.fg },
						lualine_c_normal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },

						CmpItemAbbr = { fg = theme.ui.fg },
						CmpItemAbbrMatch = { fg = theme.ui.special, bold = true },
						CmpItemKind = { fg = palette.carpYellow },
						CmpItemMenu = { fg = palette.fujiGray },

						DiffAdd = { bg = palette.winterGreen },
						DiffChange = { bg = palette.winterYellow },
						DiffDelete = { bg = palette.winterRed },
						DiffText = { bg = palette.winterBlue },

						["@variable"] = { fg = theme.ui.fg },
						["@variable.builtin"] = { fg = palette.roninYellow, italic = true },
						["@function"] = { fg = palette.carpYellow, bold = true },
						["@function.builtin"] = { fg = palette.springGreen },
						["@method"] = { fg = palette.carpYellow },
						["@parameter"] = { fg = palette.peachRed },
						["@field"] = { fg = palette.boatYellow2 },
						["@property"] = { fg = palette.springViolet2 },
						["@constructor"] = { fg = palette.crystalBlue },
						["@conditional"] = { fg = palette.autumnRed, italic = true },
						["@repeat"] = { fg = palette.autumnRed, italic = true },
						["@label"] = { fg = palette.boatYellow2 },
						["@keyword"] = { fg = palette.autumnRed, italic = true },
						["@keyword.function"] = { fg = palette.springBlue },
						["@keyword.operator"] = { fg = palette.autumnRed },
						["@operator"] = { fg = palette.springBlue },
						["@exception"] = { fg = palette.autumnRed },
						["@type"] = { fg = palette.springGreen },
						["@type.builtin"] = { fg = palette.springGreen, italic = true },
						["@structure"] = { fg = palette.waveAqua2 },
						["@include"] = { fg = palette.springBlue },
						["@annotation"] = { fg = palette.fujiGray },
						["@text.danger"] = { bg = palette.winterRed, fg = palette.fujiWhite },
						["@text.warning"] = { bg = palette.winterYellow, fg = palette.fujiWhite },
						["@text.note"] = { bg = palette.winterBlue, fg = palette.fujiWhite },
						["@text.todo"] = { bg = palette.winterGreen, fg = palette.fujiWhite },

						["@lsp.type.class.cpp"] = { fg = palette.springGreen, bold = true },
						["@lsp.type.enum.cpp"] = { fg = palette.waveAqua2 },
						["@lsp.type.namespace.cpp"] = { fg = palette.fujiGray, italic = true },
						["@lsp.type.macro.cpp"] = { fg = palette.autumnYellow },
						["@lsp.type.typedef.cpp"] = { fg = palette.springGreen },

						Terminal = { bg = theme.ui.bg, fg = theme.ui.fg },
						TerminalBorder = { fg = theme.ui.bg_m3 },
					}
				end,

				background = {
					dark = "wave",
					light = "lotus",
				},
			})

			vim.cmd.colorscheme("kanagawa-" .. theme_variant)

			-- ПРИНУДИТЕЛЬНАЯ НАСТРОЙКА РАЗДЕЛИТЕЛЕЙ ПОСЛЕ ЗАГРУЗКИ ТЕМЫ
			vim.defer_fn(function()
				-- Получаем цвет из палитры
				local colors = require("kanagawa.colors").setup()
				local yellow = colors.palette.autumnYellow

				-- Устанавливаем цвет для всех возможных разделителей
				vim.api.nvim_set_hl(0, "WinSeparator", { fg = yellow })
				vim.api.nvim_set_hl(0, "VertSplit", { fg = yellow })
				vim.api.nvim_set_hl(0, "FloatBorder", { fg = yellow })

				print("✓ Разделители установлены: " .. yellow)
			end, 100)

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
					vim.api.nvim_set_hl(0, "Normal", { bg = "#1F1F28" })
					vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1F1F28" })
					vim.notify("Прозрачность выключена", vim.log.levels.INFO)
				else
					vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
					vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
					vim.notify("Прозрачность включена", vim.log.levels.INFO)
				end
			end, { desc = "Переключить прозрачный фон" })

			print("✓ Тема Kanagawa загружена: " .. theme_variant)
		end,
	},
}

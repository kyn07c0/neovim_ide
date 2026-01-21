-- Конфигурация темы

return {
	{
		"rebelot/kanagawa.nvim",
		lazy = false, -- Загружать сразу при старте
		priority = 1000, -- Высокий приоритет (должен загружаться первым)
		config = function()
			-- Получаем настройки из core/colors.lua если они там определены
			local has_core_colors, core_colors = pcall(require, "core.colors")

			-- Настройка темы Kanagawa
			require("kanagawa").setup({
				-- Основные настройки
				compile = true, -- Включить компиляцию для более быстрой загрузки
				undercurl = true, -- Подчеркивание для курсора
				commentStyle = { italic = true },
				functionStyle = { bold = true },
				keywordStyle = { italic = true },
				statementStyle = { bold = true },
				typeStyle = {},
				transparent = false, -- Прозрачный фон (можно изменить через переменную окружения)
				dimInactive = false, -- Затемнение неактивных окон
				terminalColors = true, -- Включить цвета для терминала

				-- Цветовые схемы: wave, dragon, lotus
				theme = "wave",

				-- Дополнительные цвета
				colors = {
					theme = {
						all = {
							ui = {
								bg_gutter = "none", -- Убрать фон у gutter
								float = {
									bg = "none",
									bg_border = "none",
								},
							},
						},
					},
				},

				-- Интеграции и кастомизации
				overrides = function(colors)
					local theme = colors.theme
					local palette = colors.palette

					return {
						-- Базовые настройки для прозрачности
						Normal = { bg = "none" },
						NormalFloat = { bg = "none" },
						FloatBorder = { bg = "none", fg = theme.ui.float.bg_border or palette.fujiWhite },
						FloatTitle = { bg = "none", fg = theme.ui.special },

						-- Настройки для неактивных окон
						NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },

						-- Диагностика
						DiagnosticVirtualTextError = { bg = "none" },
						DiagnosticVirtualTextWarn = { bg = "none" },
						DiagnosticVirtualTextInfo = { bg = "none" },
						DiagnosticVirtualTextHint = { bg = "none" },

						-- LSP
						DiagnosticUnderlineError = { sp = palette.samuraiRed, undercurl = true },
						DiagnosticUnderlineWarn = { sp = palette.roninYellow, undercurl = true },
						DiagnosticUnderlineInfo = { sp = palette.dragonBlue, undercurl = true },
						DiagnosticUnderlineHint = { sp = palette.waveAqua1, undercurl = true },

						-- Telescope
						TelescopeTitle = { fg = theme.ui.special, bold = true },
						TelescopePromptNormal = { bg = theme.ui.bg_p1 },
						TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
						TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
						TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
						TelescopePreviewNormal = { bg = theme.ui.bg_dim },
						TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },

						-- Neotree/NvimTree
						NeoTreeNormal = { bg = theme.ui.bg_m3 },
						NeoTreeNormalNC = { bg = theme.ui.bg_m3 },
						NeoTreeFloatBorder = { fg = theme.ui.float.fg_border, bg = theme.ui.bg_m3 },

						-- Bufferline
						BufferLineFill = { bg = theme.ui.bg_m3 },
						BufferLineBackground = { bg = theme.ui.bg_m2, fg = theme.ui.fg_dim },
						BufferLineBufferSelected = { bg = theme.ui.bg, fg = theme.ui.fg, bold = true },
						BufferLineBufferVisible = { bg = theme.ui.bg_m1, fg = theme.ui.fg },
						BufferLineSeparatorSelected = { bg = theme.ui.bg, fg = theme.ui.bg },
						BufferLineSeparatorVisible = { bg = theme.ui.bg_m1, fg = theme.ui.bg_m1 },
						BufferLineIndicatorSelected = { fg = theme.ui.special },

						-- Lualine
						lualine_a_normal = { bg = theme.ui.special, fg = theme.ui.bg },
						lualine_b_normal = { bg = theme.ui.bg_m3, fg = theme.ui.fg },
						lualine_c_normal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },

						-- CMP (автодополнение)
						CmpItemAbbr = { fg = theme.ui.fg },
						CmpItemAbbrMatch = { fg = theme.ui.special, bold = true },
						CmpItemKind = { fg = palette.carpYellow },
						CmpItemMenu = { fg = palette.fujiGray },

						-- Git
						DiffAdd = { bg = palette.winterGreen },
						DiffChange = { bg = palette.winterYellow },
						DiffDelete = { bg = palette.winterRed },
						DiffText = { bg = palette.winterBlue },

						-- Индикаторы
						WinSeparator = { fg = theme.ui.bg_m3, bg = "none" },
						VertSplit = { fg = theme.ui.bg_m3, bg = "none" },

						-- Синтаксические группы для Treesitter
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

						-- Специфичные для C++
						["@lsp.type.class.cpp"] = { fg = palette.springGreen, bold = true },
						["@lsp.type.enum.cpp"] = { fg = palette.waveAqua2 },
						["@lsp.type.namespace.cpp"] = { fg = palette.fujiGray, italic = true },
						["@lsp.type.macro.cpp"] = { fg = palette.autumnYellow },
						["@lsp.type.typedef.cpp"] = { fg = palette.springGreen },

						-- Терминал
						Terminal = { bg = theme.ui.bg, fg = theme.ui.fg },
						TerminalBorder = { fg = theme.ui.bg_m3, bg = "none" },
					}
				end,

				-- Фоновое изображение (опционально)
				background = {
					dark = "wave", -- "wave", "dragon", "lotus"
					light = "lotus",
				},
			})

			-- Установка цветовой схемы
			local theme_variant = os.getenv("NVIM_THEME") or "wave"
			vim.cmd.colorscheme("kanagawa-" .. theme_variant)

			-- Применение дополнительных настроек после загрузки темы
			vim.defer_fn(function()
				-- Настройка прозрачности если требуется
				if os.getenv("NVIM_TRANSPARENT") == "1" then
					vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
					vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
					vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
				end

				-- Создание пользовательских команд для переключения тем
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

				-- Команда для переключения прозрачности
				vim.api.nvim_create_user_command("ToggleTransparency", function()
					local normal_hl = vim.api.nvim_get_hl_by_name("Normal", true)
					if normal_hl.background == nil then
						-- Включить фон
						vim.api.nvim_set_hl(0, "Normal", { bg = "#1F1F28" })
						vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1F1F28" })
						vim.notify("Прозрачность выключена", vim.log.levels.INFO)
					else
						-- Выключить фон
						vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
						vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
						vim.notify("Прозрачность включена", vim.log.levels.INFO)
					end
				end, { desc = "Переключить прозрачный фон" })

				-- Автоматическое применение темы при изменении файлов
				vim.api.nvim_create_autocmd("BufWritePost", {
					pattern = vim.fn.expand("~/.config/nvim/lua/**/*.lua"),
					callback = function()
						if vim.bo.filetype == "lua" then
							vim.defer_fn(function()
								vim.cmd.colorscheme("kanagawa-" .. theme_variant)
								vim.notify("Тема перезагружена", vim.log.levels.INFO)
							end, 100)
						end
					end,
					desc = "Перезагрузка темы при изменении конфигурации",
				})

				-- Интеграция с индикаторами отступов
				local ibl_ok = pcall(require, "ibl")
				if ibl_ok then
					-- Получаем цвета темы для indent-blankline
					require("kanagawa.colors").setup()

					-- Создаем кастомные группы для indent-blankline
					local indent_highlight = {
						"RainbowRed",
						"RainbowYellow",
						"RainbowBlue",
						"RainbowOrange",
						"RainbowGreen",
						"RainbowViolet",
						"RainbowCyan",
					}

					-- Создаем группы подсветки если их нет
					for i, name in ipairs(indent_highlight) do
						if vim.fn.hlexists(name) == 0 then
							local colors = {
								"#E06C75",
								"#E5C07B",
								"#61AFEF",
								"#D19A66",
								"#98C379",
								"#C678DD",
								"#56B6C2",
							}
							vim.api.nvim_set_hl(0, name, { fg = colors[i] or colors[1] })
						end
					end
				end

				print("✓ Тема Kanagawa загружена: " .. theme_variant)
			end, 100)
		end,

		-- Дополнительные настройки для lazy.nvim
		init = function()
			-- Установка переменных окружения для управления темой
			if vim.env.NVIM_THEME then
				print("Используется тема из окружения: " .. vim.env.NVIM_THEME)
			end

			-- Предварительная настройка для ускорения загрузки
			vim.opt.termguicolors = true
			vim.opt.background = "dark"
		end,
	},
}

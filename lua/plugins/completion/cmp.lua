-- Автодополнение + snippets

return {
	"hrsh7th/nvim-cmp",
	event = { "InsertEnter" }, -- Загружаем при входе в режим вставки
	dependencies = {
		{ "hrsh7th/cmp-nvim-lsp", lazy = true }, -- Источник: предложения от LSP (clangd и др.)
		{ "hrsh7th/cmp-buffer", lazy = true }, -- Источник: слова из текущего буфера
		{ "hrsh7th/cmp-path", lazy = true }, -- Источник: пути к файлам/директориям
		"hrsh7th/cmp-cmdline", -- Автодополнение в командной строке (:)
		"saadparwaiz1/cmp_luasnip", -- Интеграция с LuaSnip для сниппетов
		"hrsh7th/cmp-nvim-lsp-signature-help",

		-- Сам сниппет-движок (очень быстрый и современный)
		{
			"L3MON4D3/LuaSnip",
			version = "v2.*", -- Используем стабильную ветку v2 (актуально на 2026)
			build = "make install_jsregexp", -- Для поддержки RegExp в сниппетах (опционально, но полезно)
			dependencies = {
				"rafamadriz/friendly-snippets", -- Готовые сниппеты для C++, cpp, cmake и многих языков
			},
		},
	},

	config = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")

		-- Загружаем friendly-snippets асинхронно (они автоматически подхватываются LuaSnip)
		vim.defer_fn(function()
			require("luasnip.loaders.from_vscode").lazy_load()
		end, 100)

		-- Расширяем возможности LSP через cmp (важно!)
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

		-- Обновляем capabilities в уже настроенном clangd (чтобы не дублировать код)
		-- Если у вас lspconfig.clangd.setup уже есть — просто добавьте capabilities туда
		-- Но для удобства можно переопределить здесь (или оставить как есть)

		cmp.setup({
			-- Оптимизация производительности
			performance = {
				debounce = 60, -- ← мс между обновлениями
				throttle = 30, -- ← мс между throttle
				fetching_timeout = 500, -- ← таймаут получения
				confirm_resolve_timeout = 80,
				async_budget = 1, -- ← мс для async операций
				max_view_entries = 10, -- ← максимум видимых элементов
			},

			-- Включаем snippets
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},

			-- Сортировка и приоритет источников (очень важно для удобства)
			sources = cmp.config.sources({
				{
					-- Первое место — LSP (clangd)
					name = "nvim_lsp",
					priority = 1000,
					max_item_count = 20,
				},
				{
					name = "luasnip",
					priority = 750,
					max_item_count = 5,
				},
				{
					name = "path",
					priority = 500,
					option = { trailing_slash = true },
				},
				{
					name = "buffer",
					priority = 250,
					keyword_length = 3, -- ← только от 3 символов
					max_item_count = 10,
					option = {
						get_bufnrs = function() -- ← только видимые буферы
							local bufs = {}
							for _, win in ipairs(vim.api.nvim_list_wins()) do
								bufs[vim.api.nvim_win_get_buf(win)] = true
							end
							return vim.tbl_keys(bufs)
						end,
					},
				},
			}),

			-- Форматирование элементов меню (иконки + тип + имя)
			formatting = {
				format = function(entry, vim_item)
					-- Добавляем иконки (можно использовать nerdfonts)
					local kind_icons = {
						Text = "",
						Method = "m",
						Function = "",
						Constructor = "",
						Field = "",
						Variable = "",
						Class = "",
						Interface = "",
						Module = "",
						Property = "",
						Unit = "",
						Value = "",
						Enum = "",
						Keyword = "",
						Snippet = "",
						Color = "",
						File = "",
						Reference = "",
						Folder = "",
						EnumMember = "",
						Constant = "",
						Struct = "",
						Event = "",
						Operator = "",
						TypeParameter = "",
					}

					vim_item.kind = string.format("%s %s", kind_icons[vim_item.kind] or "", vim_item.kind)
					vim_item.menu = ({
						nvim_lsp = "[LSP]",
						luasnip = "[Snippet]",
						buffer = "[Buffer]",
						path = "[Path]",
					})[entry.source.name]

					return vim_item
				end,
			},

			-- Горячие клавиши (очень удобные и современные)
			mapping = cmp.mapping.preset.insert({
				["<C-b>"] = cmp.mapping.scroll_docs(-4), -- Прокрутка документации вверх
				["<C-f>"] = cmp.mapping.scroll_docs(4), -- вниз
				["<C-Space>"] = cmp.mapping.complete(), -- Принудительно открыть меню
				["<C-e>"] = cmp.mapping.abort(), -- Закрыть меню
				["<CR>"] = cmp.mapping.confirm({ select = true }), -- Подтвердить выбор (даже если ничего не выделено)

				-- Навигация по меню (Tab/Shift-Tab для выбора, Ctrl+j/k как в tmux)
				["<Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
					elseif luasnip.expand_or_locally_jumpable() then
						luasnip.expand_or_jump()
					else
						fallback()
					end
				end, { "i", "s" }),

				["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
					elseif luasnip.locally_jumpable(-1) then
						luasnip.jump(-1)
					else
						fallback()
					end
				end, { "i", "s" }),

				-- Джамп по placeholder'ам в сниппетах
				["<C-j>"] = cmp.mapping(function(fallback)
					if luasnip.expand_or_locally_jumpable() then
						luasnip.expand_or_jump()
					else
						fallback()
					end
				end, { "i", "s" }),

				["<C-k>"] = cmp.mapping(function(fallback)
					if luasnip.locally_jumpable(-1) then
						luasnip.jump(-1)
					else
						fallback()
					end
				end, { "i", "s" }),
			}),

			-- Производительность: не обновлять меню слишком часто
			experimental = {
				ghost_text = false, -- "призрачный" текст (отключено для производительности)
				native_menu = false,
			},
		})

		-- Автодополнение в командной строке (:)
		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = {
				{ name = "path", max_item_count = 10 },
				{ name = "cmdline", max_item_count = 20, keyword_length = 2 },
			},
		})

		-- Автодополнение в поиске (/)
		cmp.setup.cmdline({ "/", "?" }, {
			mapping = cmp.mapping.preset.cmdline(),
			sources = {
				{ name = "buffer" },
			},
		})
	end,
}

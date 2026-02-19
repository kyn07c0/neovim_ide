-- Парсер для точной подсветки, folding и т.д.

return {
	"nvim-treesitter/nvim-treesitter",
	version = false,
	build = ":TSUpdate", -- обновляет парсеры при :Lazy sync / install
	event = { "BufReadPre", "BufNewFile" }, -- Загрузка при открытии файла
	cmd = { "TSUpdate", "TSInstall", "TSUninstall" },

	config = function()
		local install_dir = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/parser"
		-- Устанавливаем нужные парсеры один раз (асинхронно)
		-- Если уже установлены — пропустит
		require("nvim-treesitter").install({
			-- Основные языки программирования
			"c", -- Язык C
			"cpp", -- Язык C++
			"cmake", -- CMake
			"make", -- Makefiles

			-- Системные языки
			"bash", -- Shell скрипты
			"python", -- Python
			"lua", -- Lua (для конфигурации Neovim)
			"vim", -- Vimscript
			"vimdoc", -- Vim documentation

			-- Веб и разметка
			"html",
			"css",
			"javascript",
			"typescript",
			"tsx",
			"json",
			"yaml",
			"toml",
			"xml",

			-- Документация
			"markdown",
			"markdown_inline",
			"latex",

			-- Другие полезные языки
			"rust",
			"go",
			"java",
			"kotlin",
			"swift",
			"dockerfile",
			"gitignore",
			"gitcommit",
			"git_config",
			"git_rebase",

			-- Специальные парсеры
			"comment", -- Комментарии
			"regex", -- Регулярные выражения
			"query", -- Treesitter queries
		})

		require("nvim-treesitter.config").setup({

			install_dir = install_dir, -- Явное указание пути установки
			auto_install = true, -- Автоматическая установка парсеров
			sync_install = false, -- Синхронная установка (может замедлить запуск)
			ignore_install = { "phpdoc", "tree-sitter-phpdoc" }, -- Игнорировать установку для определенных языков

			-- Список парсеров
			ensure_installed = {
				-- Основные языки программирования
				"c", -- Язык C
				"cpp", -- Язык C++
				"cmake", -- CMake
				"make", -- Makefiles

				-- Системные языки
				"bash", -- Shell скрипты
				"python", -- Python
				"lua", -- Lua (для конфигурации Neovim)
				"vim", -- Vimscript
				"vimdoc", -- Vim documentation

				-- Веб и разметка
				"html",
				"css",
				"javascript",
				"typescript",
				"tsx",
				"json",
				"yaml",
				"toml",
				"xml",

				-- Документация
				"markdown",
				"markdown_inline",
				"latex",

				-- Другие полезные языки
				"rust",
				"go",
				"java",
				"kotlin",
				"swift",
				"dockerfile",
				"gitignore",
				"gitcommit",
				"git_config",
				"git_rebase",

				-- Специальные парсеры
				"comment", -- Комментарии
				"regex", -- Регулярные выражения
				"query", -- Treesitter queries
			},

			-- Подсветка синтаксиса
			highlight = {
				enable = true,

				-- Использовать стандартную подсветку Vim как fallback
				additional_vim_regex_highlighting = false,
			},

			-- Автоматические отступы
			indent = { enable = true },

			-- Инкрементальный выбор
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "gnn", -- Начать выделение
					node_incremental = "grn", -- Расширить выделение
					scope_incremental = "grc", -- Выделить область
					node_decremental = "grm", -- Уменьшить выделение
				},
			},

			-- Текстовые объектв
			textobjects = {
				select = {
					enable = true,
					lookahead = true, -- Автоматически переходить вперед
					keymaps = {
						-- Для C/C++
						["af"] = "@function.outer", -- Вся функция
						["if"] = "@function.inner", -- Тело функции (без сигнатуры)
						["ac"] = "@class.outer", -- Весь класс
						["ic"] = "@class.inner", -- Тело класса
						["ab"] = "@block.outer", -- Блок кода { }
						["ib"] = "@block.inner", -- Содержимое блока
						["a/"] = "@comment.outer", -- Комментарий
						["i/"] = "@comment.inner", -- Текст комментария
					},
				},

				move = {
					enable = true,
					set_jumps = true, -- Добавить в jumplist
					goto_next_start = {
						["]m"] = "@function.outer", -- Следующая функция
						["]]"] = "@class.outer", -- Следующий класс
					},
					goto_next_end = {
						["]M"] = "@function.outer",
						["]["] = "@class.outer",
					},
					goto_previous_start = {
						["[m"] = "@function.outer", -- Предыдущая функция
						["[["] = "@class.outer", -- Предыдущий класс
					},
					goto_previous_end = {
						["[M"] = "@function.outer",
						["[]"] = "@class.outer",
					},
				},

				swap = {
					enable = true,
					swap_next = {
						["<leader>a"] = "@parameter.inner", -- Поменять аргумент с следующим
					},
					swap_previous = {
						["<leader>A"] = "@parameter.inner", -- Поменять аргумент с предыдущим
					},
				},
			},

			-- Явное связывание filetype с парсерами
			filetype_to_parsername = {
				["h"] = "c", -- .h файлы используем парсер C
				["hpp"] = "cpp", -- .hpp файлы используем парсер C++
				["hxx"] = "cpp",
				["hh"] = "cpp",
				["inl"] = "cpp",
				["ipp"] = "cpp",
				["tpp"] = "cpp",
				["txx"] = "cpp",
			},

			-- Цветные скобки
			rainbow = {
				enable = true,
				extended_mode = true, -- Также раскрашивать HTML теги
				max_file_lines = 3000, -- Не раскрашивать большие файлы
				colors = {
					"#cc241d",
					"#98971a",
					"#d79921",
					"#458588",
					"#b16286",
					"#689d6a",
					"#d65d0e",
				},
			},

			-- Контекст комментариев (для .h/.cpp)
			context_commentstring = {
				enable = true,
				enable_autocmd = false,

				-- Настройки для C/C++ файлов
				config = {
					c = "// %s",
					cpp = "// %s",
					glsl = "// %s",
				},
			},

			-- Автоматические теги
			autotag = {
				enable = true,
				filetypes = {
					"html",
					"xml",
					"javascript",
					"typescript",
					"javascriptreact",
					"typescriptreact",
					"svelte",
					"vue",
					"tsx",
					"jsx",
					"markdown",
				},
			},

			-- Сопоставление скобок и тегов
			matchup = {
				enable = true,
				include_match_words = true,
			},

			-- Отладка TREESITTER
			playground = {
				enable = true,
				disable = {},
				updatetime = 25, -- Обновлять каждые 25 мс
				persist_queries = false,
				keybindings = {
					toggle_query_editor = "o",
					toggle_hl_groups = "i",
					toggle_injected_languages = "t",
					toggle_anonymous_nodes = "a",
					toggle_language_display = "I",
					focus_language = "f",
					unfocus_language = "F",
					update = "R",
					goto_node = "<cr>",
					show_help = "?",
				},
			},

			-- Проверка запросов
			query_linter = {
				enable = true,
				use_virtual_text = true,
				lint_events = { "BufWrite", "CursorHold" },
			},

			-- Рефакторинг
			refactor = {
				highlight_definitions = {
					enable = true,
					clear_on_cursor_move = true,
				},
				highlight_current_scope = {
					enable = false, -- Может быть навязчивым
				},
				smart_rename = {
					enable = true,
					keymaps = {
						smart_rename = "grr", -- Переименование с учетом контекста
					},
				},
				navigation = {
					enable = true,
					keymaps = {
						goto_definition = "gnd", -- Перейти к определению
						list_definitions = "gnD", -- Список определений
						list_definitions_toc = "gO", -- Содержание
						goto_next_usage = "<a-*>", -- Следующее использование
						goto_previous_usage = "<a-#>", -- Предыдущее использование
					},
				},
			},
		})

		-- Автозапуск подсветки только после успешной установки парсера
		vim.api.nvim_create_autocmd({ "FileType" }, {
			pattern = { "c", "cpp", "lua", "vim", "markdown", "json", "yaml", "bash" },
			callback = function(ev)
				local ok, _ = pcall(vim.treesitter.start, ev.buf)
				if not ok then
					-- Если парсер ещё не готов — пробуем позже (через 100 мс)
					vim.defer_fn(function()
						pcall(vim.treesitter.start, ev.buf)
					end, 100)
				end
			end,
		})

		-- Folding для C/C++ (точный, на основе дерева)
		vim.api.nvim_create_autocmd({ "FileType" }, {
			pattern = { "c", "cpp" },
			callback = function()
				vim.wo.foldmethod = "expr"
				vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.wo.foldenable = false -- не сворачивать сразу при открытии
			end,
		})

		-- Indent на основе treesitter (экспериментально, но полезно)
		vim.api.nvim_create_autocmd({ "FileType" }, {
			pattern = { "c", "cpp", "lua" },
			callback = function()
				vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end,
		})

		-- Настройка цветов для методов класса
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = function()
				-- Методы классов (отличаются от обычных функций)
				vim.api.nvim_set_hl(0, "@function.method", { fg = "#ff9e64", bold = true })
				vim.api.nvim_set_hl(0, "@function.method.call", { fg = "#ff9e64", italic = true })

				-- Обычные функции
				vim.api.nvim_set_hl(0, "@function.call", { fg = "#7aa2f7" })
				vim.api.nvim_set_hl(0, "@function", { fg = "#7aa2f7", bold = true })

				-- Конструкторы/деструкторы
				vim.api.nvim_set_hl(0, "@constructor", { fg = "#e0af68", bold = true })

				-- Поля классов
				vim.api.nvim_set_hl(0, "@field", { fg = "#9ece6a" })
				vim.api.nvim_set_hl(0, "@property", { fg = "#9ece6a", italic = true })

				-- Переменные члены класса (через LSP семантические токены)
				vim.api.nvim_set_hl(0, "@lsp.type.method", { link = "@function.method" })
				vim.api.nvim_set_hl(0, "@lsp.typemod.method.defaultLibrary", { fg = "#ff9e64", bold = true })
				vim.api.nvim_set_hl(0, "@lsp.type.property", { link = "@property" })
				vim.api.nvim_set_hl(0, "@lsp.type.variable", { fg = "#c0caf5" })
				vim.api.nvim_set_hl(0, "@lsp.typemod.variable.classScope", { fg = "#c0caf5", italic = true })
			end,
		})

		-- Применить сразу, если цветовая схема уже загружена
		if vim.g.colors_name then
			vim.cmd("doautocmd ColorScheme")
		end
	end,
}

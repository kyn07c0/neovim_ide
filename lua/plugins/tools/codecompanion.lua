return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-treesitter/nvim-treesitter",
		-- Опционально, но очень рекомендуется:
		{ "MeanderingProgrammer/render-markdown.nvim", opts = {} }, -- красивый markdown в чате
	},
	opts = {
		-- По умолчанию будет использоваться первый доступный адаптер
		-- Порядок: copilot → openai → anthropic → ollama и т.д.
		adapters = {
			-- 1. Ollama (локально, самый популярный бесплатный вариант в 2026)
			ollama = function()
				return require("codecompanion.adapters").extend("ollama", {
					schema = {
						model = { default = "qwen3:8b" },
						-- Очень важно для Qwen3 — увеличить контекст, если память позволяет
						num_ctx = {
							default = 32768, -- или 65536 / 128000 если ≥24–32 GB VRAM
						},

						-- Опционально: температура ниже → код более предсказуемый
						temperature = {
							default = 0.6,
						},
					},
					-- env = { url = "http://127.0.0.1:11434" },  -- по умолчанию так
				})
			end,

			-- 2. Anthropic Claude (очень сильный в коде, если есть подписка)
			anthropic = function()
				return require("codecompanion.adapters").extend("anthropic", {
					env = { api_key = "cmd:pass show anthropic/api-key" }, -- или os.getenv("ANTHROPIC_API_KEY")
					schema = {
						model = { default = "claude-3-7-sonnet-20250219" }, -- или claude-4-opus если уже вышел
					},
				})
			end,

			-- 3. GitHub Copilot (если у тебя уже есть подписка)
			copilot = function()
				return require("codecompanion.adapters").extend("copilot", {
					schema = {
						model = { default = "gpt-4o" }, -- или copilot-claude-3.5-sonnet и т.п.
					},
				})
			end,
		},

		-- Какой адаптер использовать по умолчанию в чате
		strategies = {
			chat = {
				adapter = "ollama",

				context = {
					strategy = "files",
					files = function()
						-- Автоматически находит корень по .codecompanion/
						local root = vim.fn.getcwd()
						for _ = 1, 15 do
							if (vim.uv or vim.loop).fs_stat(root .. "/.codecompanion") then
								break
							end
							local parent = vim.fn.fnamemodify(root, ":h")
							if parent == root or parent == "" then
								root = vim.fn.getcwd()
								break
							end
							root = parent
						end

						-- Сканируем файлы проекта
						local files = {}
						local function scan(dir)
							local iter = vim.loop.fs_scandir(dir)
							if not iter then
								return
							end
							while true do
								local name, typ = vim.loop.fs_scandir_next(iter)
								if not name then
									break
								end
								local full = dir .. "/" .. name
								if typ == "directory" then
									if not name:match("^%.") and not name:match("^(build|cmake%-build)") then
										scan(full)
									end
								elseif typ == "file" then
									if
										name:match("%.cpp$")
										or name:match("%.h$")
										or name:match("CMakeLists%.txt$")
										or name:match("^Makefile$")
									then
										table.insert(files, full)
									end
								end
							end
						end
						scan(root)
						return files
					end,
				},
			},
			inline = {
				adapter = "ollama",
			},
		},

		-- Горячие клавиши (очень удобно)
		keys = {
			{ "<leader>cc", "<cmd>CodeCompanionChat<CR>", mode = { "n", "v" }, desc = "AI Chat" },
			{ "<leader>ca", "<cmd>CodeCompanionActions<CR>", mode = { "n", "v" }, desc = "AI Actions" },
			{ "<leader>ci", "<cmd>CodeCompanion<CR>", mode = "n", desc = "Inline suggest" },
			{ "ga", "<cmd>CodeCompanionAdd<CR>", mode = "v", desc = "Add selection to chat" },
		},

		-- Красивый и удобный чат
		display = {
			chat = {
				window = {
					width = 0.45, -- 45% ширины экрана
					height = 0.8,
					border = "rounded",
				},
			},
			diff = {
				enabled = true,
				layout = "float", -- или "buffer" если хочешь в отдельном буфере
			},
		},

		-- Полезные фишки
		opts = {
			log_level = vim.log.levels.WARN, -- DEBUG если хочешь отлаживать
			language = "Русский", -- подсказки на русском (если модель поддерживает)

			-- Qwen3 любит чёткие системные промпты
			system_prompt = function()
				return [[
Ты — эксперт по программированию.
Предоставляйте только окончательное решение/код
Никаких объяснений, никакого описания хода рассуждений, никаких комментариев по поводу ваших рассуждений.
Если вам нужно что-то объяснить, сделайте это максимум одним коротким предложением.
Выводите чистый, готовый к использованию в продакшене код напрямую.
В ответе используй русский язык.
]]
			end,
		},
	},

	-- Необязательно, но делает чат намного красивее
	config = function(_, opts)
		---@diagnostic disable-next-line: undefined-field
		require("codecompanion").setup(opts)

		-- Модуль для работы с контекстом проекта
		local project_utils = {
			-- Найти корень проекта через простой цикл (без plenary.path)
			get_root = function()
				local path = vim.fn.getcwd()
				local max_depth = 15

				for _ = 1, max_depth do
					-- Ищем маркеры проекта
					for _, marker in ipairs({
						".git",
						"CMakeLists.txt",
						"Makefile",
						".codecompanion",
					}) do
						local full_path = path .. "/" .. marker
						if (vim.uv or vim.loop).fs_stat(full_path) then
							return path
						end
					end

					-- Поднимаемся вверх
					local parent = vim.fn.fnamemodify(path, ":h")
					if parent == path or parent == "" then
						break
					end
					path = parent
				end

				return vim.fn.getcwd() -- fallback
			end,

			-- Получить список файлов проекта
			get_project_files = function(root)
				local patterns = {
					"%.cpp$",
					"%.cc$",
					"%.cxx$",
					"%.h$",
					"%.hpp$",
					"%.hxx$",
					"%.c$",
					"CMakeLists%.txt$",
					"Makefile$",
					"makefile$",
					"%.cmake$",
					"%.json$",
					"%.toml$",
					"%.yaml$",
					"%.yml$",
					"README%.md$",
					"LICENSE$",
				}

				local ignore_patterns = {
					"build/",
					"cmake%-build%-",
					"%.git/",
					"%.vscode/",
					"%.idea/",
					"%.o$",
					"%.a$",
					"%.so$",
					"%.dll$",
					"%.exe$",
					"compile_commands%.json",
				}

				local files = {}
				local function scan(dir)
					local iter = vim.loop.fs_scandir(dir)
					if not iter then
						return
					end

					while true do
						local name, type = vim.loop.fs_scandir_next(iter)
						if not name then
							break
						end

						local full = dir .. "/" .. name

						-- Пропускаем игнорируемые
						local skip = false
						for _, pat in ipairs(ignore_patterns) do
							if name:match(pat) or full:match(pat) then
								skip = true
								break
							end
						end
						if skip then
							goto continue
						end

						if type == "directory" then
							scan(full)
						elseif type == "file" then
							for _, pat in ipairs(patterns) do
								if name:match(pat) then
									table.insert(files, full)
									break
								end
							end
						end
						::continue::
					end
				end

				scan(root)
				return files
			end,
		}

		-- Регистрируем модуль глобально для доступа из <leader>cd
		_G.cc_project = project_utils
		package.loaded["cc-project"] = project_utils

		-- Команда: добавить все файлы проекта в чат
		vim.api.nvim_create_user_command("CCAddProjectContext", function()
			local root = project_utils.get_root()
			local files = project_utils.get_project_files(root)

			if #files == 0 then
				vim.notify(
					"⚠️ Не найдено файлов для контекста проекта",
					vim.log.levels.WARN
				)
				return
			end

			-- Добавляем файлы в текущий чат через буфер
			local lines = { "=== КОНТЕКСТ ПРОЕКТА (" .. root .. ") ===", "" }
			for _, file in ipairs(files) do
				local content = vim.fn.readfile(file)
				if #content > 0 then
					-- Добавляем заголовок файла
					table.insert(lines, "📁 " .. file:gsub(root .. "/", ""))
					table.insert(lines, "```cpp")

					-- Добавляем содержимое построчно (макс 200 строк)
					local line_count = 0
					for _, line in ipairs(content) do
						if line_count >= 200 then
							table.insert(
								lines,
								"... (файл обрезан для экономии контекста)"
							)
							break
						end
						table.insert(lines, line)
						line_count = line_count + 1
					end

					table.insert(lines, "```")
					table.insert(lines, "") -- пустая строка между файлами
				end
			end

			-- Открываем чат и вставляем контекст
			vim.cmd("CodeCompanionChat")
			vim.defer_fn(function()
				local chat_buf = vim.api.nvim_get_current_buf()

				vim.bo[chat_buf].modifiable = true
				vim.api.nvim_buf_set_lines(chat_buf, 0, 0, false, lines)
				vim.bo[chat_buf].modifiable = false
				vim.notify(
					"✅ Добавлено " .. #files .. " файлов в контекст",
					vim.log.levels.INFO
				)
			end, 100)
		end, {})

		-- Авто-уведомление при открытии
		vim.api.nvim_create_autocmd("VimEnter", {
			once = true,
			callback = function()
				local root = project_utils.get_root()
				vim.notify(
					"📁 CodeCompanion: корень проекта — " .. root:gsub("/home/yura/", "~/"),
					vim.log.levels.INFO,
					{ title = "CodeCompanion" }
				)
			end,
		})

		-- Пример: быстрый переключатель модели через команду
		vim.api.nvim_create_user_command("CCModel", function(args)
			---@diagnostic disable-next-line: undefined-field
			require("codecompanion").set_adapter(args.args)
		end, {
			nargs = 1,
			complete = function()
				return { "ollama", "anthropic", "copilot", "openai" }
			end,
		})
	end,
}

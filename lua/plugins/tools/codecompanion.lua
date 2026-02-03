return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
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
						model = {
							default = "qwen3:8b", -- или deepseek-coder-v2, codestral, llama3.3-70b и т.д.
						},
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
			system_prompt = function(opts)
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
		require("codecompanion").setup(opts)

		-- Пример: быстрый переключатель модели через команду
		vim.api.nvim_create_user_command("CCModel", function(opts)
			require("codecompanion").set_adapter(opts.args)
		end, {
			nargs = 1,
			complete = function()
				return { "ollama", "anthropic", "copilot", "openai" }
			end,
		})
	end,
}

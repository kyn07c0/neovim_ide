-- which-key.nvim — показывает подсказки для горячих клавиш после нажатия <leader>

return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		plugins = {
			marks = true,
			registers = true,
			spelling = {
				enabled = true,
				suggestions = 20,
			},
			presets = {
				operators = true,
				motions = true,
				text_objects = true,
				windows = true,
				nav = true,
				z = true,
				g = true,
			},
		},

		win = {
			border = "rounded",
			position = "bottom",
			no_overlap = true,
		},

		sort = { "local", "order", "group", "alphanum", "mod" },

		icons = {
			breadcrumb = "»",
			separator = "➜",
			group = "+",
		},

		delay = function(ctx)
			return ctx.ctype == "mapping" and 0 or 500
		end,

		show_help = true,
		show_keys = true,

		-- Правильный способ включить триггер на <leader> в новых версиях (v3+)
		-- "<auto>" — автоматически настраивает триггеры для всех режимов
		-- Можно явно указать "<leader>" как строку
		triggers = { "<auto>" }, -- ← это обычно работает лучше всего
		-- Альтернатива, если "<auto>" не сработает:
		-- triggers = { "<leader>" },

		defer = function(ctx)
			return ctx.mode == "n" and ctx.key == "<leader>"
		end,
	},

	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)

		-- Регистрируем группы БЕЗ ДУБЛИКАТОВ
		wk.add({
			-- Корневой префикс (часто решает проблему с неотображением после <leader>)
			{ "<leader>", group = "leader" },

			-- Уникальные группы (удалены дубли)
			{ "<leader>f", group = "find/telescope" },
			{ "<leader>l", group = "lsp" },
			{ "<leader>d", group = "debug/dap" },
			{ "<leader>c", group = "code/format/cmake" },
			{ "<leader>g", group = "git" },
			{ "<leader>s", group = "surround/swap" },

			-- Конкретные маппинги с описаниями
			{ "<leader>ff", desc = "Find files" },
			{ "<leader>fg", desc = "Live grep" },
			{ "<leader>fb", desc = "Buffers" },
			{ "<leader>fs", desc = "Workspace symbols" },
			{ "<leader>fd", desc = "Document symbols" },
			{ "<leader>fr", desc = "References" },
			{ "<leader>b", desc = "Toggle breakpoint" },
			{ "<leader>cf", desc = "Format buffer" },
			{ "<leader>du", desc = "Toggle DAP UI" },
			{ "<leader>dr", desc = "Toggle REPL" },
		})
	end,
}

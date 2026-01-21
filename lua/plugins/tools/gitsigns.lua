-- gitsigns.nvim — навигация по изменениям файлов

return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
			untracked = { text = "▎" },
		},
		signcolumn = true, -- всегда показывать колонку
		numhl = false, -- подсветка номера строки (можно включить)
		linehl = false,
		word_diff = false,
		watch_gitdir = { interval = 1000, follow_files = true },
		attach_to_untracked = true,
		current_line_blame = false, -- включите, если хотите blame в строке
		current_line_blame_opts = {
			virt_text = true,
			virt_text_pos = "eol",
			delay = 1000,
			ignore_whitespace = false,
		},
		sign_priority = 6,
		update_debounce = 100,
		status_formatter = nil,
		max_file_length = 40000,
		preview_config = {
			border = "rounded",
			style = "minimal",
			relative = "cursor",
			row = 0,
			col = 1,
		},

		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns

			local function map(mode, l, r, opts)
				opts = opts or {}
				opts.buffer = bufnr
				vim.keymap.set(mode, l, r, opts)
			end

			-- Навигация по hunk'ам
			map("n", "]h", function()
				if vim.wo.diff then
					return "]h"
				end
				vim.schedule(function()
					gs.next_hunk()
				end)
				return "<Ignore>"
			end, { expr = true, desc = "Next Hunk" })

			map("n", "[h", function()
				if vim.wo.diff then
					return "[h"
				end
				vim.schedule(function()
					gs.prev_hunk()
				end)
				return "<Ignore>"
			end, { expr = true, desc = "Prev Hunk" })

			-- Действия с hunk'ами
			map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", { desc = "Stage Hunk" })
			map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", { desc = "Reset Hunk" })
			map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage Buffer" })
			map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo Stage Hunk" })
			map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset Buffer" })
			map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview Hunk" })
			map("n", "<leader>hb", function()
				gs.blame_line({ full = true })
			end, { desc = "Blame Line" })
			map("n", "<leader>hd", gs.diffthis, { desc = "Diff This" })
			map("n", "<leader>hD", function()
				gs.diffthis("~")
			end, { desc = "Diff This ~" })

			-- Интеграция с which-key (опционально)
			local wk = require("which-key")
			wk.add({
				{ "<leader>h", group = "hunks (gitsigns)" },
				{ "<leader>hs", desc = "Stage hunk" },
				{ "<leader>hr", desc = "Reset hunk" },
				-- ... остальные
			})
		end,
	},
}

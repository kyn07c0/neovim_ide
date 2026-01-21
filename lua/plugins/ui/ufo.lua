-- nvim-ufo — продвинутый folding с preview и treesitter-поддержкой

return {
	"kevinhwang91/nvim-ufo",
	dependencies = {
		"kevinhwang91/promise-async",
	},
	event = { "BufReadPost", "BufNewFile" },

	config = function()
		-- Рекомендуемые настройки для ufo + treesitter
		vim.o.foldcolumn = "1" -- показывать колонку fold (1 символ)
		vim.o.foldlevel = 99 -- не сворачивать ничего по умолчанию (zR / zm для управления)
		vim.o.foldlevelstart = 99
		vim.o.foldenable = true

		-- Используем treesitter как основной провайдер folding
		require("ufo").setup({
			provider_selector = function(bufnr, filetype, buftype)
				return { "treesitter", "indent" } -- сначала treesitter, fallback на indent
			end,

			-- Красивый preview при hover над folded строкой
			preview = {
				win_config = {
					border = { "", "─", "", "", "", "─", "", "" },
					winhighlight = "Normal:Folded",
					winblend = 0,
				},
			},

			-- Отключить в некоторых файлах (опционально)
			open_fold_hl_timeout = 150,
			close_fold_kinds_for_ft = {
				default = { "imports", "comment" },
			},
			enable_get_fold_virt_text = true,

			-- Кастомный текст для folded строк (очень красиво)
			fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
				local newVirtText = {}
				local suffix = " 󰇘 " .. (endLnum - lnum + 1) .. " lines "
				local sufWidth = vim.fn.strdisplaywidth(suffix)
				local targetWidth = width - sufWidth
				local curWidth = 0

				for _, chunk in ipairs(virtText) do
					local chunkText = chunk[1]
					local chunkWidth = vim.fn.strdisplaywidth(chunkText)
					if targetWidth > curWidth + chunkWidth then
						table.insert(newVirtText, chunk)
					else
						chunkText = truncate(chunkText, targetWidth - curWidth)
						local hlGroup = chunk[2]
						table.insert(newVirtText, { chunkText, hlGroup })
						chunkWidth = vim.fn.strdisplaywidth(chunkText)
						-- Добавляем ellipsis если обрезано
						if curWidth + chunkWidth < targetWidth then
							suffix = suffix .. "…"
						end
						break
					end
					curWidth = curWidth + chunkWidth
				end

				table.insert(newVirtText, { suffix, "MoreMsg" })
				return newVirtText
			end,
		})

		-- Горячие клавиши для folding
		vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
		vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
		vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds, { desc = "Open folds except kinds" })
		vim.keymap.set("n", "zm", require("ufo").closeFoldsWith, { desc = "Close folds with level" })

		-- Прыжок к следующему/предыдущему fold
		vim.keymap.set("n", "]z", require("ufo").goNextClosedFold, { desc = "Next closed fold" })
		vim.keymap.set("n", "[z", require("ufo").goPreviousClosedFold, { desc = "Prev closed fold" })

		-- Для preview при hover (по умолчанию zK, но можно изменить)
		vim.keymap.set("n", "zK", function()
			local winid = require("ufo").peekFoldedLinesUnderCursor()
			if not winid then
				vim.lsp.buf.hover()
			end
		end, { desc = "Peek folded lines or LSP hover" })
	end,
}

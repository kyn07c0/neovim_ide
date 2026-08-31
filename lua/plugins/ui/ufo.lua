-- Продвинутый folding с preview и treesitter-поддержкой

return {
	"kevinhwang91/nvim-ufo",
	dependencies = { "kevinhwang91/promise-async" },
	event = "VeryLazy",

	config = function()
		-- Настройка сворачивания
		vim.o.foldlevel = 99 -- не сворачивать по умолчанию
		vim.o.foldlevelstart = 99 -- при старте редактора ничего не сворачивать
		vim.o.foldenable = true -- разрешить ручное сворачивание
		vim.o.foldmethod = "manual" -- только ручное сворачивание

		-- Используем treesitter как основной провайдер folding
		require("ufo").setup({
			provider_selector = function(bufnr, filetype, buftype)
				-- Игнорируем специальные буферы
				if buftype ~= "" then
					return nil
				end

				-- Отключаем для больших файлов
				local line_count = vim.api.nvim_buf_line_count(bufnr)

				if line_count > 5000 then
					return { "indent" }
				end

				-- В огромных файлах отключаем сворачивания полностью
				if line_count > 50000 then
					return nil
				end

				return { "treesitter", "indent" }
			end,

			-- Ekexityysq preview
			preview = {
				win_config = {
					border = "rounded",
					winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
					winblend = 10,
					maxheight = 20,
					relative = "cursor",
				},
				mappings = {
					scrollU = "<C-u>",
					scrollD = "<C-d>",
					jumpTop = "[",
					jumpBot = "]",
				},
			},

			-- Улучшенный визуальный текст для сворачиваемых строк
			fold_virt_text_handler = function(virtText, lnum, endLnum, width)
				local newVirtText = {}
				local total_lines = vim.api.nvim_buf_line_count(0)

				-- Показываем процент от файла и количество строк
				local folded_lines = endLnum - lnum
				local percentage = math.floor((folded_lines / total_lines) * 100)

				-- Иконка + количество строк + процент
				local suffix = (" 󰁂 %d lines (%d%%) "):format(folded_lines, percentage)
				local sufWidth = vim.fn.strdisplaywidth(suffix)
				local targetWidth = width - sufWidth

				-- Собираем видимый текст с усечением
				local curWidth = 0
				for _, chunk in ipairs(virtText) do
					local chunkText = chunk[1]
					local chunkWidth = vim.fn.strdisplaywidth(chunkText)

					if curWidth + chunkWidth > targetWidth then
						-- Усечение с многоточием
						local remaining = targetWidth - curWidth - 3
						if remaining > 3 then
							table.insert(
								newVirtText,
								{ chunkText:sub(1, vim.fn.byteidx(chunkText, remaining)) .. "...", chunk[2] }
							)
						end
						break
					end

					table.insert(newVirtText, chunk)
					curWidth = curWidth + chunkWidth
				end

				table.insert(newVirtText, { suffix, "MoreMsg" })
				return newVirtText
			end,

			-- Включить подсветку отступов для indent-провайдера
			enable_get_fold_virt_text = false,
		})

		local ufo = require("ufo")

		-- Горячие клавиши для folding
		vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
		vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
		vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds, { desc = "Open folds except kinds" })
		vim.keymap.set("n", "zm", require("ufo").closeFoldsWith, { desc = "Close folds with level" })

		-- Прыжок к следующему/предыдущему fold
		vim.keymap.set("n", "]z", require("ufo").goNextClosedFold, { desc = "Next closed fold" })
		vim.keymap.set("n", "[z", require("ufo").goPreviousClosedFold, { desc = "Prev closed fold" })

		-- Preview с fallback на LSP
		vim.keymap.set("n", "K", function()
			local winid = ufo.peekFoldedLinesUnderCursor()
			if not winid then
				vim.lsp.buf.hover()
			end
		end, { desc = "Peek fold or LSP hover" })

		-- Быстрое сворачивание под курсором
		vim.keymap.set("n", "za", function()
			-- Если fold открыт - закрыть, если закрыт - открыть
			if ufo.inspectFoldedLinesUnderCursor() then
				ufo.openFoldsExceptKinds()
			else
				ufo.closeFoldsWith(1)
			end
		end, { desc = "Toggle fold under cursor" })

		-- Открыть fold и перейти к первой строке содержимого
		vim.keymap.set("n", "zo", function()
			ufo.openFoldsExceptKinds()
			vim.cmd("normal! zv")
		end, { desc = "Open fold and view" })

		-- ============================================
		-- 7. АВТОКОМАНДЫ ДЛЯ СПЕЦИФИЧНЫХ ФАЙЛОВ
		-- ============================================
		local augroup = vim.api.nvim_create_augroup("UfoConfig", { clear = true })

		-- Для git diff показывать только изменения свернутыми
		vim.api.nvim_create_autocmd("FileType", {
			group = augroup,
			pattern = { "git" },
			callback = function()
				vim.opt_local.foldlevel = 0
				vim.opt_local.foldenable = true
			end,
		})

		-- Для help всегда открыты
		vim.api.nvim_create_autocmd("FileType", {
			group = augroup,
			pattern = { "help", "man" },
			callback = function()
				vim.opt_local.foldenable = false
			end,
		})
	end,
}

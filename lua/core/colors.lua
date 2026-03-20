-- Настройки цветов и темы

-- Включение true colors
if vim.fn.has("termguicolors") == 1 then
	vim.opt.termguicolors = true
end

-- Настройки прозрачности
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1e1e2e" })
vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#89b4fa", bg = "#1e1e2e" })
vim.api.nvim_set_hl(0, "FloatTitle", { fg = "#f38ba8", bold = true })

-- Кастомные группы подсветки для indent-blankline
local function setup_indent_highlight()
	-- Создаем группы подсветки для indent-blankline
	local colors = {
		red = "#E06C75",
		yellow = "#E5C07B",
		blue = "#61AFEF",
		orange = "#D19A66",
		green = "#98C379",
		violet = "#C678DD",
		cyan = "#56B6C2",
	}

	vim.api.nvim_set_hl(0, "RainbowRed", { fg = colors.red })
	vim.api.nvim_set_hl(0, "RainbowYellow", { fg = colors.yellow })
	vim.api.nvim_set_hl(0, "RainbowBlue", { fg = colors.blue })
	vim.api.nvim_set_hl(0, "RainbowOrange", { fg = colors.orange })
	vim.api.nvim_set_hl(0, "RainbowGreen", { fg = colors.green })
	vim.api.nvim_set_hl(0, "RainbowViolet", { fg = colors.violet })
	vim.api.nvim_set_hl(0, "RainbowCyan", { fg = colors.cyan })
end

-- Инициализация подсветки
setup_indent_highlight()

-- Автокоманда для перезагрузки подсветки при смене цветовой схемы
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = setup_indent_highlight,
	desc = "Перезагрузка подсветки indent-blankline",
})

print("✓ Настройки цветов загружены")

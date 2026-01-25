-- Глобальные клавиши (не связанные с плагинами)
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

---------- ОСНОВНЫЕ КЛАВИШИ ----------

-- Сохранение и выход
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Сохранить" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Выйти" })
map("n", "<leader>Q", "<cmd>q!<cr>", { desc = "Выйти без сохранения" })
map("n", "<leader>x", "<cmd>x<cr>", { desc = "Сохранить и выйти" })

-- Навигация по окнам
map("n", "<C-h>", "<C-w>h", { desc = "Перейти в левое окно" })
map("n", "<C-j>", "<C-w>j", { desc = "Перейти в нижнее окно" })
map("n", "<C-k>", "<C-w>k", { desc = "Перейти в верхнее окно" })
map("n", "<C-l>", "<C-w>l", { desc = "Перейти в правое окно" })

-- Изменение размера окон
map("n", "<M-h>", "<cmd>vertical resize -2<cr>", { desc = "Уменьшить ширину окна" })
map("n", "<M-l>", "<cmd>vertical resize +2<cr>", { desc = "Увеличить ширину окна" })
map("n", "<M-j>", "<cmd>resize -2<cr>", { desc = "Уменьшить высоту окна" })
map("n", "<M-k>", "<cmd>resize +2<cr>", { desc = "Увеличить высоту окна" })

-- Перемещение строк
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Переместить выделение вниз" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Переместить выделение вверх" })
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Переместить строку вниз" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Переместить строку вверх" })

-- Поиск и замена
map(
	"n",
	"<leader>s",
	":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>",
	{ desc = "Заменить слово под курсором" }
)
map("n", "<leader>S", ":%s///g<Left><Left>", { desc = "Глобальная замена" })
map("n", "n", "nzzzv", { desc = "Следующий результат поиска с центрированием" })
map(
	"n",
	"N",
	"Nzzzv",
	{ desc = "Предыдущий результат поиска с центрированием" }
)

-- Системный буфер обмена
map("v", "<leader>y", '"+y', { desc = "Копировать в системный буфер" })
map("n", "<leader>Y", '"+Y', { desc = "Копировать строку в системный буфер" })
map("n", "<leader>p", '"+p', { desc = "Вставить из системного буфера" })
map(
	"n",
	"<leader>P",
	'"+P',
	{ desc = "Вставить перед курсором из системного буфера" }
)

-- Управление вкладками
map("n", "<leader>tn", "<cmd>tabnew<cr>", { desc = "Новая вкладка" })
map("n", "<leader>tc", "<cmd>tabclose<cr>", { desc = "Закрыть вкладку" })
map("n", "<leader>to", "<cmd>tabonly<cr>", { desc = "Оставить только текущую вкладку" })
map("n", "<leader>th", "<cmd>tabprevious<cr>", { desc = "Предыдущая вкладка" })
map("n", "<leader>tl", "<cmd>tabnext<cr>", { desc = "Следующая вкладка" })

---------- РЕДАКТИРОВАНИЕ ----------

-- Отмена и повтор
map("n", "U", "<C-r>", { desc = "Повторить" })

-- Выделение всего
map("n", "<leader>a", "ggVG", { desc = "Выделить весь файл" })

-- Переключение регистра
map("n", "<leader>u", "viwU", { desc = "Сделать слово заглавными" })
map("n", "<leader>U", "viwu", { desc = "Сделать слово строчными" })

-- Вставка без форматирования
map("n", "<leader>p", '"_dP', { desc = "Вставить без перезаписи регистра" })

-- Быстрое редактирование
map("n", "<leader>;", "A;<esc>", { desc = "Добавить точку с запятой в конец строки" })
map("n", "<leader>,", "A,<esc>", { desc = "Добавить запятую в конец строки" })

---------- НАВИГАЦИЯ ПО ФАЙЛАМ ----------

-- Переход к началу/концу с отступом
map("n", "<C-d>", "<C-d>zz", { desc = "Прокрутить вниз с центрированием" })
map("n", "<C-u>", "<C-u>zz", { desc = "Прокрутить вверх с центрированием" })

-- Сохранить текущую позицию
map("n", "m", "m", { desc = "Сохранить позицию" })
map("n", "'", "`", { desc = "Перейти к сохраненной позиции" })

---------- УПРАВЛЕНИЕ ПРОЕКТОМ ----------

-- Перезагрузка конфигурации
map("n", "<leader>sv", "<cmd>source $MYVIMRC<cr>", { desc = "Перезагрузить конфигурацию" })
map("n", "<leader>ev", "<cmd>edit $MYVIMRC<cr>", { desc = "Редактировать конфигурацию" })

-- Создание директорий для несуществующих файлов
map("n", "<leader>md", function()
	local dir = vim.fn.expand("%:p:h")
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
		print("Создана директория: " .. dir)
	end
end, { desc = "Создать директорию для файла" })

---------- ТЕРМИНАЛ ----------

-- Открытие терминала
map("n", "<leader>tt", function()
	vim.cmd("split | terminal")
	vim.cmd("startinsert")
end, { desc = "Открыть терминал" })

map("t", "<Esc>", "<C-\\><C-n>", { desc = "Выйти из режима терминала" })

---------- СПЕЦИФИЧНЫЕ ДЛЯ ЯЗЫКОВ ----------

-- C++ комментарии
map("n", "<leader>cc", "i// <esc>", { desc = "Добавить комментарий C++" })
map("v", "<leader>cc", ":norm i// <cr>", { desc = "Закомментировать выделение C++" })

-- Быстрое создание C++ файла
map("n", "<leader>cn", function()
	local filename = vim.fn.input("Имя файла (без .cpp): ")
	if filename ~= "" then
		local template = [[#include <iostream>
#include <vector>
#include <string>

using namespace std;

int main() {
    cout << "Hello, C++!" << endl;
    return 0;
}]]
		vim.cmd("e " .. filename .. ".cpp")
		vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(template, "\n"))
	end
end, { desc = "Создать новый C++ файл" })

-- Быстрое создание заголовочного файла
map("n", "<leader>ch", function()
	local current_file = vim.fn.expand("%:t")
	local base_name = current_file:match("(.+)%..+$") or current_file

	if current_file:match("%.cpp$") or current_file:match("%.c$") then
		local header_name = base_name .. ".h"
		if not vim.fn.filereadable(header_name) then
			local header_content = string.format(
				[[#ifndef %s_H
#define %s_H

// Объявления функций и классов

#endif // %s_H
]],
				base_name:upper(),
				base_name:upper(),
				base_name:upper()
			)

			vim.cmd("vsplit " .. header_name)
			vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(header_content, "\n"))
			print("Создан заголовочный файл: " .. header_name)
		else
			vim.cmd("vsplit " .. header_name)
		end
	end
end, { desc = "Создать/открыть заголовочный файл" })

-- Автозаполнение для вставки пути
map("n", "<leader>cp", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	print("Путь скопирован в буфер: " .. path)
end, { desc = "Копировать путь к файлу" })

---------- УТИЛИТЫ ----------

-- Переключение относительных номеров
map("n", "<leader>rn", function()
	vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, { desc = "Переключить относительные номера строк" })

-- Переключение переноса строк
map("n", "<leader>wr", function()
	vim.opt.wrap = not vim.opt.wrap:get()
end, { desc = "Переключить перенос строк" })

-- Очистка поиска
map("n", "<leader>nh", "<cmd>nohlsearch<cr>", { desc = "Очистить подсветку поиска" })

-- Показать непечатаемые символы
map("n", "<leader>l", function()
	vim.opt.list = not vim.opt.list:get()
end, { desc = "Показать/скрыть непечатаемые символы" })

-- Показать диагностику
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Показать диагностику" })
map("n", "[d", vim.diagnostic.get_prev, { desc = "Предыдущая диагностика" })
map("n", "]d", vim.diagnostic.get_next, { desc = "Следующая диагностика" })

---------- МАКРОСЫ ----------

-- Упрощенное использование макросов
map("n", "Q", "@q", { desc = "Выполнить макрос q" })
map("x", "Q", ":norm @q<cr>", { desc = "Выполнить макрос q на выделении" })

---------- ПЛАГИНЫ ----------

---------- LSP ----------
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
map("n", "gr", vim.lsp.buf.references, { desc = "References" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

---------- TELESCOPE ----------
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help tags" })
map("n", "<leader>fs", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", { desc = "Workspace symbols" })
map("n", "<leader>fd", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "Document symbols" })
map("n", "<leader>fu", "<cmd>Telescope undo<cr>", { desc = "Undo history" })
map("n", "<leader>fp", "<cmd>Telescope projects<cr>", { desc = "Projects" })

---------- DAP (Отладка) ----------
map("n", "<F5>", function()
	require("dap").continue()
end, { desc = "Debug: continue" })
map("n", "<F10>", function()
	require("dap").step_over()
end, { desc = "Debug: step over" })
map("n", "<F11>", function()
	require("dap").step_into()
end, { desc = "Debug: step into" })
map("n", "<F12>", function()
	require("dap").step_out()
end, { desc = "Debug: step out" })
map("n", "<leader>db", function()
	require("dap").toggle_breakpoint()
end, { desc = "Debug: toggle breakpoint" })
map("n", "<leader>du", function()
	require("dapui").toggle()
end, { desc = "Debug: toggle UI" })
map("n", "<leader>dr", function()
	require("dap").repl.toggle()
end, { desc = "Debug: toggle REPL" })
map("n", "<leader>dc", "<cmd>Telescope dap commands<cr>", { desc = "DAP commands" })
map("n", "<leader>dbp", "<cmd>Telescope dap list_breakpoints<cr>", { desc = "DAP breakpoints" })

---------- NEO-TREE ----------
map("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file explorer" })
map("n", "<leader>o", "<cmd>Neotree focus<cr>", { desc = "Focus file explorer" })

---------- BUFFERLINE ----------
map("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
map("n", "<leader>tn", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
map("n", "<leader>tp", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })

---------- TREESITTER ----------
map("n", "gnn", function()
	require("nvim-treesitter.incremental_selection").init_selection()
end, { desc = "Start selection" })
map("n", "grn", function()
	require("nvim-treesitter.incremental_selection").node_incremental()
end, { desc = "Increment selection" })
map("n", "grm", function()
	require("nvim-treesitter.incremental_selection").node_decremental()
end, { desc = "Decrement selection" })
map("n", "grc", function()
	require("nvim-treesitter.incremental_selection").scope_incremental()
end, { desc = "Scope selection" })

---------- CONFORM (Форматирование) ----------
map({ "n", "v" }, "<leader>cf", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })

---------- TODO-COMMENTS ----------
map("n", "]c", function()
	require("todo-comments").jump_next()
end, { desc = "Next todo comment" })
map("n", "[c", function()
	require("todo-comments").jump_prev()
end, { desc = "Previous todo comment" })
map("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Todo telescope" })

---------- GITSIGNS ----------
map("n", "]h", function()
	require("gitsigns").next_hunk()
end, { desc = "Next git hunk" })
map("n", "[h", function()
	require("gitsigns").prev_hunk()
end, { desc = "Previous git hunk" })
map({ "n", "v" }, "<leader>hs", "<cmd>Gitsigns stage_hunk<cr>", { desc = "Stage hunk" })
map({ "n", "v" }, "<leader>hr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "Reset hunk" })

---------- CMakeTools ----------
map("n", "<leader>cg", function()
	require("cmake-tools").generate()
end, { desc = "CMake generate" })
map("n", "<leader>cb", function()
	require("cmake-tools").build()
end, { desc = "CMake build" })
map("n", "<leader>cr", function()
	require("cmake-tools").run()
end, { desc = "CMake run" })
map("n", "<leader>cd", "<cmd>CMakeDebug<cr>", { desc = "CMake debug" })
map("n", "<leader>cc", "<cmd>CMakeClean<cr>", { desc = "CMake Clean" })
map("n", "<leader>ct", "<cmd>CMakeSelectTarget<cr>", { desc = "Select Target" })
map("n", "<leader>co", "<cmd>CMakeOpen<cr>", { desc = "Open CMake console" })
map("n", "<leader>cx", "<cmd>CMakeClose<cr>", { desc = "Close CMake console" })

---------- UFO (Folding) ----------
map("n", "zR", function()
	require("ufo").openAllFolds()
end, { desc = "Open all folds" })
map("n", "zM", function()
	require("ufo").closeAllFolds()
end, { desc = "Close all folds" })

---------- EASY-ALIGN ----------
map({ "n", "x" }, "ga", "<Plug>(EasyAlign)", { desc = "Easy align" })

print("✓ Глобальные клавиши загружены")

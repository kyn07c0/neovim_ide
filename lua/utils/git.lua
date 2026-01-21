-- Утилиты для работы с Git

local M = {}

function M.init()
	-- Инициализация Git утилит
	print("✓ Git утилиты инициализированы")
end

-- Проверить, является ли текущий каталог Git репозиторием
function M.is_git_repo()
	local cwd = vim.fn.getcwd()
	local git_dir = cwd .. "/.git"
	return vim.fn.isdirectory(git_dir) == 1
end

-- Получить текущую ветку
function M.get_current_branch()
	if not M.is_git_repo() then
		return nil
	end

	local result = vim.fn.system("git branch --show-current 2>/dev/null")
	if result and result ~= "" then
		return result:gsub("\n", "")
	end

	return nil
end

-- Получить статус репозитория
function M.get_git_status()
	if not M.is_git_repo() then
		return nil
	end

	local status = {
		branch = M.get_current_branch() or "unknown",
		modified = 0,
		staged = 0,
		untracked = 0,
	}

	-- Получаем статус файлов
	local result = vim.fn.system("git status --porcelain 2>/dev/null")
	if result and result ~= "" then
		for line in result:gmatch("[^\r\n]+") do
			local status_code = line:sub(1, 2)

			if status_code:match("^[MADRC]") then
				status.staged = status.staged + 1
			elseif status_code:match("^[MADR]") then
				status.modified = status.modified + 1
			elseif status_code == "??" then
				status.untracked = status.untracked + 1
			end
		end
	end

	return status
end

-- Показать информацию о коммите под курсором
function M.show_commit_info()
	local line = vim.api.nvim_get_current_line()
	local commit_hash = line:match("[a-f0-9]+")

	if commit_hash and #commit_hash >= 7 then
		local cmd = "git show --stat " .. commit_hash .. " 2>/dev/null | head -20"
		local result = vim.fn.system(cmd)

		if result and result ~= "" then
			-- Создаем временный буфер для просмотра
			vim.cmd("vsplit")
			vim.cmd("enew")
			vim.bo.buftype = "nofile"
			vim.bo.bufhidden = "wipe"
			vim.bo.swapfile = false

			local lines = vim.split(result, "\n")
			vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

			vim.bo.filetype = "git"
			vim.bo.modifiable = false

			vim.api.nvim_buf_set_name(0, "git-commit-" .. commit_hash:sub(1, 7))
		end
	else
		vim.notify("Не найден хэш коммита на текущей строке", vim.log.levels.WARN)
	end
end

-- Создать новую ветку
function M.create_branch()
	if not M.is_git_repo() then
		vim.notify("Не Git репозиторий", vim.log.levels.ERROR)
		return
	end

	local branch_name = vim.fn.input("Имя новой ветки: ")
	if branch_name == "" then
		return
	end

	local cmd = "git checkout -b " .. branch_name
	vim.cmd("vsplit | terminal " .. cmd)
	vim.cmd("startinsert")
end

-- Переключиться на ветку
function M.switch_branch()
	if not M.is_git_repo() then
		vim.notify("Не Git репозиторий", vim.log.levels.ERROR)
		return
	end

	-- Получаем список веток
	local result = vim.fn.system("git branch --format='%(refname:short)' 2>/dev/null")
	if not result or result == "" then
		vim.notify("Не удалось получить список веток", vim.log.levels.ERROR)
		return
	end

	local branches = {}
	for branch in result:gmatch("[^\r\n]+") do
		table.insert(branches, branch)
	end

	-- Показываем список в Telescope
	local pickers = require("utils.functions").safe_require("telescope.pickers")
	local finders = require("utils.functions").safe_require("telescope.finders")
	local conf = require("utils.functions").safe_require("telescope.config").values

	if pickers and finders and conf then
		local opts = {}

		pickers
			.new(opts, {
				prompt_title = "Выберите ветку",
				finder = finders.new_table({
					results = branches,
				}),
				sorter = conf.generic_sorter(opts),
				attach_mappings = function(prompt_bufnr, map)
					map("i", "<CR>", function()
						local selection = require("telescope.actions.state").get_selected_entry()
						require("telescope.actions").close(prompt_bufnr)

						if selection then
							local cmd = "git checkout " .. selection[1]
							vim.cmd("vsplit | terminal " .. cmd)
							vim.cmd("startinsert")
						end
					end)
					return true
				end,
			})
			:find()
	else
		-- Простой выбор
		vim.ui.select(branches, {
			prompt = "Выберите ветку:",
		}, function(choice)
			if choice then
				local cmd = "git checkout " .. choice
				vim.cmd("vsplit | terminal " .. cmd)
				vim.cmd("startinsert")
			end
		end)
	end
end

-- Просмотреть историю файла
function M.view_file_history()
	local filename = vim.fn.expand("%")

	if filename == "" then
		vim.notify("Файл не сохранен", vim.log.levels.ERROR)
		return
	end

	local cmd = "git log --oneline -- " .. vim.fn.shellescape(filename)
	vim.cmd("vsplit | terminal " .. cmd)
	vim.cmd("startinsert")
end

-- Создать коммит с интерактивным выбором изменений
function M.create_commit()
	if not M.is_git_repo() then
		vim.notify("Не Git репозиторий", vim.log.levels.ERROR)
		return
	end

	-- Сначала показываем статус
	vim.cmd("vsplit | terminal git status")
	vim.cmd("startinsert")

	-- После закрытия терминала спросим о сообщении коммита
	vim.api.nvim_create_autocmd("TermClose", {
		buffer = 0,
		once = true,
		callback = function()
			local commit_message = vim.fn.input("Сообщение коммита: ")
			if commit_message and commit_message ~= "" then
				local cmd = 'git commit -m "' .. commit_message .. '"'
				vim.cmd("split | terminal " .. cmd)
				vim.cmd("startinsert")
			end
		end,
	})
end

-- Показать diff текущего файла
function M.show_file_diff()
	local filename = vim.fn.expand("%")

	if filename == "" then
		vim.notify("Файл не сохранен", vim.log.levels.ERROR)
		return
	end

	local cmd = "git diff " .. vim.fn.shellescape(filename)
	vim.cmd("vsplit")
	vim.cmd("enew")
	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.swapfile = false

	local result = vim.fn.system(cmd)
	if result and result ~= "" then
		local lines = vim.split(result, "\n")
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	else
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Нет изменений" })
	end

	vim.bo.filetype = "diff"
	vim.bo.modifiable = false
	vim.api.nvim_buf_set_name(0, "git-diff-" .. vim.fn.fnamemodify(filename, ":t"))
end

-- Пользовательские команды
vim.api.nvim_create_user_command("GitStatus", function()
	local status = M.get_git_status()
	if status then
		local message = string.format(
			"Ветка: %s\nИзмененные: %d\nВ индексе: %d\nНеотслеживаемые: %d",
			status.branch,
			status.modified,
			status.staged,
			status.untracked
		)
		vim.notify(message, vim.log.levels.INFO)
	else
		vim.notify("Не Git репозиторий", vim.log.levels.WARN)
	end
end, {
	desc = "Показать статус Git репозитория",
})

vim.api.nvim_create_user_command("GitShowCommit", M.show_commit_info, {
	desc = "Показать информацию о коммите под курсором",
})

vim.api.nvim_create_user_command("GitCreateBranch", M.create_branch, {
	desc = "Создать новую ветку",
})

vim.api.nvim_create_user_command("GitSwitchBranch", M.switch_branch, {
	desc = "Переключиться на другую ветку",
})

vim.api.nvim_create_user_command("GitFileHistory", M.view_file_history, {
	desc = "Просмотреть историю текущего файла",
})

vim.api.nvim_create_user_command("GitCommit", M.create_commit, {
	desc = "Создать коммит",
})

vim.api.nvim_create_user_command("GitDiff", M.show_file_diff, {
	desc = "Показать diff текущего файла",
})

return M

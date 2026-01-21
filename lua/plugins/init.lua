local plugins = {}

-- Порядок загрузки важен!
local plugin_sections = {
	"ui", -- Интерфейс (темы, статусные строки) - ПЕРВЫМ!
	"core", -- Базовые плагины
	"lsp", -- LSP и языковая поддержка
	"completion", -- Автодополнение
	"navigation", -- Навигация
	"tools", -- Инструменты разработки
	"debugging", -- Отладка
	"languages", -- Языковые специфичные плагины
}

for _, section in ipairs(plugin_sections) do
	local ok, section_plugins = pcall(require, "plugins." .. section)
	if ok and section_plugins then
		if type(section_plugins) == "table" then
			-- Если это таблица с плагинами (не вложенная таблица)
			if #section_plugins > 0 then
				-- Это уже список плагинов
				for _, plugin in ipairs(section_plugins) do
					table.insert(plugins, plugin)
				end
			else
				-- Это единичный плагин
				table.insert(plugins, section_plugins)
			end
		end
	else
		-- Можно логировать отсутствие секции
		vim.notify("Секция plugins." .. section .. " не найдена", vim.log.levels.DEBUG)
	end
end

return plugins

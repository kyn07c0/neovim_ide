-- Показывает значения переменных прямо в коде во время отладки

return {
	"theHamsta/nvim-dap-virtual-text",
	dependencies = { "mfussenegger/nvim-dap" },
	event = "VeryLazy",

	config = function()
		require("nvim-dap-virtual-text").setup({
			enabled = true, -- включено по умолчанию
			enabled_commands = true, -- команды :DapVirtualTextEnable и т.д.
			highlight_changed_variables = true, -- подсвечивать изменённые переменные
			highlight_new_as_changed = true, -- новые переменные тоже как изменённые
			show_stop_reason = true, -- показывать причину остановки
			commented = false, -- не показывать в закомментированных строках
			only_first_definition = true, -- только первое определение переменной
			all_frames = false, -- показывать во всех фреймах стека (может быть шумно)
			virt_text_pos = "eol", -- позиция: "eol" (конец строки), "overlay", "right_align"
			virt_lines = false, -- экспериментально: показывать в отдельных строках
			-- Форматирование значений (очень полезно для C++: vector, map и т.д.)
			display_callback = function(variable)
				if variable.name == "this" then
					return variable.value:gsub("^%s*(.-)%s*$", "%1") -- убрать лишние пробелы
				end

				-- Короткие имена для STL
				if variable.value:match("^std::vector") or variable.value:match("^std::map") then
					return variable.name .. " = " .. variable.value:sub(1, 50) .. "..."
				end

				return variable.name .. " = " .. variable.value
			end,

			-- Цвета (подстраиваются под тему)
			virt_text_win_col = 80, -- если virt_text_pos = "right_align"
		})

		-- Автоматически включать/выключать при старте отладки
		local dap = require("dap")
		dap.listeners.after.event_initialized["dap-virtual-text"] = function()
			require("nvim-dap-virtual-text").enable()
		end

		dap.listeners.before.event_terminated["dap-virtual-text"] = function()
			require("nvim-dap-virtual-text").disable()
		end

		dap.listeners.before.event_exited["dap-virtual-text"] = function()
			require("nvim-dap-virtual-text").disable()
		end
	end,
}

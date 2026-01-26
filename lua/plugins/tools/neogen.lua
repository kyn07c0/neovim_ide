-- Генератор документации и комментариев для функций/классов

return {
	"danymat/neogen",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	cmd = "Neogen",
	keys = {
		{ "<leader>ng", "<cmd>Neogen<cr>", desc = "Generate documentation" },
	},

	config = function()
		require("neogen").setup({
			enabled = true,
			input_after_comment = true, -- курсор сразу в комментарий после генерации

			-- Генератор по умолчанию — doxygen для C++
			snippet_engine = "luasnip", -- если используешь LuaSnip (из cmp)

			languages = {
				cpp = {
					template = {
						annotation_convention = "doxygen", -- или "google", "rustdoc"
						-- Кастомные шаблоны, если хочешь изменить
						doxygen = {
							function_type = {
								template = {
									annotation = {
										"/// @brief ${1:Brief description}",
										"///",
										"/// @param ${2:param} ${3:Description}",
										"/// @return ${4:return type} ${5:Description}",
									},
								},
							},
							class_type = {
								template = {
									annotation = {
										"/// @class ${1:ClassName}",
										"/// @brief ${2:Brief description}",
									},
								},
							},
						},
					},
				},
			},

			-- Маппинги (можно добавить больше)
			placeholder_text = {
				description = "Description",
				parameter = "Parameter",
				return_type = "Return type",
			},

			-- Автоматическая генерация при определённых условиях (опционально)
			-- enabled = true,
			-- place_after_comment = true,
		})

		-- Дополнительные клавиши
		vim.keymap.set("n", "<leader>nf", function()
			require("neogen").generate({ type = "func" })
		end, { desc = "Generate function doc" })

		vim.keymap.set("n", "<leader>nc", function()
			require("neogen").generate({ type = "class" })
		end, { desc = "Generate class doc" })
	end,
}

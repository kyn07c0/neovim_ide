-- Улучшенная навигация по C++ коду

return {
  "p00f/clangd_extensions.nvim",
  dependencies = { "neovim/nvim-lspconfig" },
  config = function()
    require("clangd_extensions").setup({
      inlay_hints = {
        inline = true,
        only_current_line = false,
        show_parameter_hints = true,
        parameter_hints_prefix = " ← ",
        other_hints_prefix = " → ",
        max_len_align = false,
        max_len_align_padding = 1,
        right_align = false,
        right_align_padding = 7,
        highlight = "Comment",
        priority = 100,
      },
      ast = {
        role_icons = {
          type = "",
          declaration = "",
          expression = "",
          statement = "",
          specifier = "",
          ["template argument"] = "",
        },
        kind_icons = {
          Compound = "",
          Recovery = "",
          TranslationUnit = "",
          PackExpansion = "",
          TemplateTypeParm = "",
          TemplateTemplateParm = "",
          TemplateParamObject = "",
        },
      },
    })
  end,
}

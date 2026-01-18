-- gitsigns.nvim — git интеграция

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },  -- загружаем при открытии файла
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },

    signcolumn = true,      -- всегда показывать колонку слева
    numhl = false,          -- подсветка номера строки (можно включить)
    linehl = false,         -- подсветка всей строки
    word_diff = false,      -- подсветка изменённых слов (можно включить для детальности)

    watch_gitdir = {
      interval = 1000,
      follow_files = true,
    },

    attach_to_untracked = true,
    current_line_blame = false,  -- авто blame текущей строки (можно включить)

    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol",     -- конец строки
      delay = 1000,
      ignore_whitespace = false,
      virt_text_priority = 100,
    },

    current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",

    sign_priority = 6,
    update_debounce = 100,
    status_formatter = nil,  -- дефолтный
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

      -- Навигация по hunk'ам (expr = true → возвращаем строку или <Ignore>)
      map("n", "]h", function()
        if vim.wo.diff then
          return "]h"
        end
        vim.schedule(function() gs.next_hunk() end)
        return "<Ignore>"
      end, { expr = true, desc = "Next Hunk" })

      map("n", "[h", function()
        if vim.wo.diff then
          return "[h"
        end
        vim.schedule(function() gs.prev_hunk() end)
        return "<Ignore>"
      end, { expr = true, desc = "Prev Hunk" })

      -- Действия
      map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", { desc = "Stage Hunk" })
      map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", { desc = "Reset Hunk" })
      map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage Buffer" })
      map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo Stage Hunk" })
      map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset Buffer" })
      map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview Hunk" })
      map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Blame Line (full)" })
      map("n", "<leader>hd", gs.diffthis, { desc = "Diff This" })
      map("n", "<leader>hD", function() gs.diffthis("~") end, { desc = "Diff This ~" })

      -- Текстовые объекты
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "GitSigns Select Hunk" })
    end,
  },
}

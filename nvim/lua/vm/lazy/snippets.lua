return {
  {
    "L3MON4D3/LuaSnip",
    -- follow latest release.
    version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
    -- install jsregexp (optional!).
    build = "make install_jsregexp",

    dependencies = { "rafamadriz/friendly-snippets" },

    config = function()
      local ls = require("luasnip")
      ls.filetype_extend("javascript", { "jsdoc" })

      vim.keymap.set({ "i" }, "<C-s>e", function() ls.expand() end, { silent = true })

      vim.keymap.set({ "i", "s" }, "<C-s>,", function() ls.jump(1) end, { silent = true })
      vim.keymap.set({ "i", "s" }, "<C-s>.", function() ls.jump(-1) end, { silent = true })

      vim.keymap.set({ "i", "s" }, "<C-E>", function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { silent = true })
    end,
  }
}

-- return {
--   {
--     "danymat/neogen",
--     dependencies = {
--       "nvim-treesitter/nvim-treesitter",
--       'L3MON4D3/LuaSnip',
--     },
--     version = "*",
--     config = function()
--       local neogen = require('neogen')
--       neogen.setup({
--         snippet_engine = "luasnip"
--       })

--       vim.keymap.set("n", "<leader>nf", function()
--         neogen.generate({ type = "func" })
--       end)
--       vim.keymap.set("n", "<leader>nt", function()
--         neogen.generate({ type = "type" })
--       end)
--       vim.keymap.set("n", "<leader>nd", function()
--         neogen.generate({ type = "typedef" })
--       end)
--     end
--   }
-- }

return {
  {
    "folke/zen-mode.nvim",
    config = function()
      local zen = require("zen-mode")
      local ui = require("config.ui")

      vim.keymap.set("n", "<leader>zz", function()
        zen.setup({
          window = {
            width = 130,
            options = {},
          },
        })
        zen.toggle()
        vim.wo.wrap = false
        vim.wo.number = true
        vim.wo.rnu = true
        ui.ColorMyPencils()
      end)

      vim.keymap.set("n", "<leader>zZ", function()
        zen.setup({
          window = {
            width = 80,
            options = {},
          },
        })
        zen.toggle()
        vim.wo.wrap = false
        vim.wo.number = false
        vim.wo.rnu = false
        vim.opt.colorcolumn = "0"
        ui.ColorMyPencils()
      end)
    end,
  },
}

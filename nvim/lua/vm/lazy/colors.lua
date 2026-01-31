return {
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    priority = 1000,
    lazy = false,
    config = function()
      require('rose-pine').setup({
        disable_background = true,
        styles = {
          italic = false,
        },
      })
      require("config.ui").ColorMyPencils("rose-pine")
    end
  },
  {
    'folke/tokyonight.nvim',
    name = 'tokyonight',
    priority = 1000,
    lazy = true,
    config = function()
      require("tokyonight").setup({
        style = "storm",        -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
        transparent = true,     -- Enable this to disable setting the background color
        terminal_colors = true, -- Configure the colors used when opening a `:terminal` in [Neovim](https://github.com/neovim/neovim)
        styles = {
          comments = { italic = false },
          keywords = { italic = false },
          sidebars = "dark", -- style for sidebars, see below
          floats = "dark",   -- style for floating windows
        }
      })
      -- require("config.ui").ColorMyPencils("tokyonight")
    end
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = true,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- latte, frappe, macchiato, mocha
        transparent_background = true,
        integrations = {
          cmp = true,
          gitsigns = true,
          harpoon = true,
          mason = true,
          telescope = true,
          treesitter = true,
          treesitter_context = true,
          lsp_trouble = false,
          markdown = true,
          fidget = true,
        },
      })
      -- require("config.ui").ColorMyPencils("catppuccin")
    end
  },
}

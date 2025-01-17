function ColorMyPencils(color)
  color = color or "catppuccin"
  vim.cmd.colorscheme(color)

  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

return {
  {
    'folke/tokyonight.nvim',
    name = 'tokyonight',
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
      -- ColorMyPencils("tokyonight")
    end
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
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
      -- ColorMyPencils("catppuccin")
    end
  },
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    config = function()
      require('rose-pine').setup({
        disable_background = true,
        styles = {
          italic = false,
        },
      })
      ColorMyPencils("rose-pine")
    end
  }
}

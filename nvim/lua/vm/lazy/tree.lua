return {
  "nvim-tree/nvim-tree.lua",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    local nvimtree = require("nvim-tree")

    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    nvimtree.setup({
      sort = {
        sorter = "case_sensitive",
      },
      view = {
        width = 35,
        relativenumber = true,
      },
      renderer = {
        group_empty = true,
        indent_markers = {
          enable = true,
        },
        icons = {
          glyphs = {
            folder = {
              arrow_closed = "🠺",
              arrow_open = "🠻",
            }
          }
        }
      },
      actions = {
        open_file = {
          window_picker = {
            enable = false
          }
        }
      },
      filters = {
        --dotfiles = true,
      },
      git = {
        ignore = false
      }
    })

    vim.keymap.set("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>")
    vim.keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFileToggle<CR>")
    vim.keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>")
    vim.keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>")
  end
}

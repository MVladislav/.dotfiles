-- =====================
-- Base settings & setup
-- =====================
require("vm.set")
require("vm.remap")
require("vm.lazy_init")

-- =====================
-- Helper functions
-- =====================
function R(name)
  require("plenary.reload").reload_module(name)
end

-- =====================
-- Autocommands
-- =====================
local augroup = vim.api.nvim_create_augroup
local VmGroup = augroup("vm", {})

-- Highlight text after yank
local yank_group = augroup("HighlightYank", {})
vim.api.nvim_create_autocmd("TextYankPost", {
  group = yank_group,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch",
      timeout = 40,
    })
  end,
})

-- =====================
-- Netrw configuration
-- =====================
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

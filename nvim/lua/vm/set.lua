-- Better netrw
vim.g.netrw_liststyle = 3

-- UI
vim.opt.background = "dark"
vim.opt.guicursor = "" -- stable cursor in all modes
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.colorcolumn = "130"
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Tabs & indent
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.breakindent = true
vim.opt.wrap = false

-- Undo & backup
vim.opt.swapfile = false
vim.opt.backup = false
local undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.fn.mkdir(undodir, "p")
vim.opt.undodir = undodir
vim.opt.undofile = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Scrolling
vim.opt.scrolloff = 8

-- Performance
vim.opt.updatetime = 200 -- more responsive LSP, default=4000ms

-- Completion
vim.opt.completeopt = { "menuone", "noselect" }

-- Folds (for nvim-ufo)
vim.opt.foldcolumn = "1"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- Misc
vim.opt.isfname:append("@-@")
vim.opt.backspace = "indent,eol,start"
if vim.fn.has("clipboard") == 1 then
  vim.opt.clipboard = "unnamedplus"
end

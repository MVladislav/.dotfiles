vim.cmd("let g:netrw_liststyle = 3")

vim.opt.background = "dark"
vim.opt.guicursor = ""
-- vim.opt.guicursor = {
--   "n-v-c:block",                                 -- Normal, visual, command-line: block cursor
--   "i-ci-ve:ver25",                               -- Insert, command-line insert, visual-exclude: vertical bar cursor with 25% width
--   "r-cr:hor20",                                  -- Replace, command-line replace: horizontal bar cursor with 20% height
--   "o:hor50",                                     -- Operator-pending: horizontal bar cursor with 50% height
--   "a:blinkwait700-blinkoff400-blinkon250",       -- All modes: blinking settings
--   "sm:block-blinkwait175-blinkoff150-blinkon175", -- Showmatch: block cursor with specific blinking settings
-- }

-- Enable relative line numbers
vim.opt.nu = true
vim.opt.rnu = true
vim.opt.relativenumber = true

-- Set tabs to 2 spaces
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

-- Enable auto indenting and set it to spaces
vim.opt.shiftwidth = 2
vim.opt.smartindent = true

-- Enable smart indenting (see https://stackoverflow.com/questions/1204149/smart-wrap-in-vim)
vim.opt.breakindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
-- Enable persistent undo history
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- incremental searching
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Enable 24-bit color
vim.opt.termguicolors = true

-- Always keep 8 lines above/below cursor unless at start/end of file
vim.opt.scrolloff = 8
-- Enable the sign column to prevent the screen from jumping
vim.opt.signcolumn = "yes"

vim.opt.isfname:append("@-@")

-- Decrease updatetime to 200ms
vim.opt.updatetime = 50

-- Place a column line
vim.opt.colorcolumn = "130"

-- Better splitting
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Enable mouse mode
vim.opt.mouse = "a"

-- Enable ignorecase + smartcase for better searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Set completeopt to have a better completion experience
vim.opt.completeopt = { "menuone", "noselect" }

-- Enable cursor line highlight
vim.opt.cursorline = true

-- Set fold settings
-- These options were recommended by nvim-ufo
-- See: https://github.com/kevinhwang91/nvim-ufo#minimal-configuration
vim.opt.foldcolumn = "0"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

vim.opt.clipboard = 'unnamedplus'

vim.opt.backspace = "indent,eol,start"

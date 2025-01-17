local keymap = vim.keymap

vim.g.mapleader = " "
vim.g.maplocalleader = " "

keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Move selected lines up/down
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Combine current line with line below
keymap.set("n", "J", "mzJ`z")

-- Cursor jump centered
keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")
-- Search next/prev
keymap.set("n", "n", "nzzzv")
keymap.set("n", "N", "Nzzzv")

-- greatest remap ever
keymap.set("x", "<leader>p", [["_dP]])

-- Copy modes
keymap.set({ "n", "v" }, "<leader>y", [["+y]])
keymap.set("n", "<leader>Y", [["+Y]])

keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- This is going to get me cancelled
keymap.set("i", "<C-c>", "<Esc>")
keymap.set("n", "Q", "<nop>")

-- New tmux session with fzf search
keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- Format with lsp
keymap.set("n", "<leader>f", vim.lsp.buf.format)

keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

keymap.set('n', '<leader>h', ':nohlsearch<CR>')

local function vimgrep_current_word()
  -- Get the current word under the cursor
  local current_word = vim.fn.expand("<cword>")
  -- Run vimgrep with the current word in all files in the current directory
  vim.cmd("vimgrep /" .. current_word .. "/ `find . -type f`")
  -- Open the quickfix list
  vim.cmd("copen")

  -- Prompt the user for the new word
  local new_word = vim.fn.input("Replace with: ")
  -- Run :cdo command to replace current_word with new_word
  vim.cmd("cdo %s/" .. current_word .. "/" .. new_word .. "/gc")
end
keymap.set("n", "<leader>rnl", vimgrep_current_word, { silent = true })

local function vimgrep_current_word()
  -- Get the current word under the cursor
  local current_word = vim.fn.expand("<cword>")
  -- Run vimgrep with the current word in all files in the current directory
  vim.cmd("vimgrep /" .. current_word .. "/ %")
  -- Open the quickfix list
  vim.cmd("copen")

  -- Prompt the user for the new word
  local new_word = vim.fn.input("Replace with: ")
  -- Run :cdo command to replace current_word with new_word
  vim.cmd("cdo %s/" .. current_word .. "/" .. new_word .. "/gc")
end
keymap.set("n", "<leader>rnf", vimgrep_current_word, { silent = true })

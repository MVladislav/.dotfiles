-- Keymaps configuration
local keymap = vim.keymap

-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- File navigation
keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Open netrw file explorer" })

-- Move selected lines up/down
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Join current line with the one below, keeping cursor in place
keymap.set("n", "J", "mzJ`z", { desc = "Join line below (keep cursor)" })

-- Cursor jumps (keep centered)
keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Page down (centered)" })
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Page up (centered)" })

-- Search navigation (keep centered)
keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
keymap.set("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

-- Paste without overwriting register
keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })

-- Copy (yank) to system clipboard
keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })

-- Delete without affecting register
keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- Quality-of-life mappings
keymap.set("i", "<C-c>", "<Esc>", { desc = "Escape insert mode" })
keymap.set("n", "Q", "<nop>", { desc = "Disable Q (Ex mode)" })

-- New tmux session with fzf search (safe check for tmux)
keymap.set("n", "<C-f>", function()
  if vim.fn.exists("$TMUX") == 1 then
    vim.cmd("silent !tmux neww tmux-sessionizer")
  else
    print("Not running inside tmux")
  end
end, { desc = "Open tmux sessionizer" })

-- Format with LSP
keymap.set("n", "<leader>f", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format buffer with LSP" })

-- Quickfix and location list navigation
keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Next quickfix item" })
keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Prev quickfix item" })
keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next location list item" })
keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Prev location list item" })

-- Search & replace word under cursor
keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Search & replace word under cursor" }
)

-- Make current file executable
keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make file executable" })

-- Clear search highlight
keymap.set("n", "<leader>h", ":nohlsearch<CR>", { desc = "Clear search highlight" })

-- Replace word in project
local function vimgrep_replace_all()
  local current_word = vim.fn.expand("<cword>")
  vim.cmd("vimgrep /" .. current_word .. "/ `find . -type f`")
  vim.cmd("copen")
  local new_word = vim.fn.input("Replace with: ")
  vim.cmd("cdo %s/" .. current_word .. "/" .. new_word .. "/gc")
end
keymap.set("n", "<leader>rnp", vimgrep_replace_all, { silent = true, desc = "Replace word in project" })

-- Replace word in current file
local function vimgrep_replace_file()
  local current_word = vim.fn.expand("<cword>")
  vim.cmd("vimgrep /" .. current_word .. "/ %")
  vim.cmd("copen")
  local new_word = vim.fn.input("Replace with: ")
  vim.cmd("cdo %s/" .. current_word .. "/" .. new_word .. "/gc")
end
keymap.set("n", "<leader>rnf", vimgrep_replace_file, { silent = true, desc = "Replace word in file" })

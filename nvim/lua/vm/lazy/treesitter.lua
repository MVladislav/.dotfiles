return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = 'main',
    build = ":TSUpdate",
    config = function()
      local parsers = {
        "sh",
        "bash",
        "css",
        "dockerfile",
        "git_config",
        "gitattributes",
        "gitignore",
        "html",
        "java",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "markdown",
        "python",
        "query",
        "rust",
        "toml",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
        "zig",
      }
      require('nvim-treesitter').install(parsers)

      require('nvim-treesitter').install({ 'templ' })
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'templ',
        callback = function()
          vim.treesitter.start()
        end,
      })

      vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.opt.foldmethod = "expr"
      vim.opt.foldcolumn = "0"
      vim.opt.foldtext = ""
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 4
      vim.opt.foldnestmax = 4

      -- Function to set fold level and fold blocks
      local function FoldToLevel(level)
        -- Close all folds first (zM), then set the fold level
        vim.cmd("normal! zM") -- Close all folds
        vim.opt.foldlevel = level
        -- Open folds up to the specific level (e.g., z1, z2, etc.)
        vim.cmd("normal! z" .. level)
      end

      -- Map ALT+k ALT+0 to fold unfold
      vim.keymap.set("n", "<A-k><A-0>", function() vim.cmd("normal! zR") end)
      -- Map ALT+k ALT+1 to fold depth 1
      vim.keymap.set("n", "<A-k><A-1>", function() FoldToLevel(0) end)
      -- Map ALT+k ALT+2 to fold depth 2
      vim.keymap.set("n", "<A-k><A-2>", function() FoldToLevel(1) end)
      -- Map ALT+k ALT+3 to fold depth 3
      vim.keymap.set("n", "<A-k><A-3>", function() FoldToLevel(2) end)
      -- Map ALT+k ALT+4 to fold depth 4
      vim.keymap.set("n", "<A-k><A-4>", function() FoldToLevel(4) end)
      -- Map ALT+k ALT+5 to fold depth 5
      vim.keymap.set("n", "<A-k><A-5>", function() FoldToLevel(5) end)
    end,
  },
}

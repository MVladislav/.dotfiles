return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.config").setup({
        ensure_installed = {
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
        },
        sync_install = false,
        auto_install = true,
        indent = { enable = true },

        highlight = {
          enable = true,
          disable = function(lang, buf)
            if lang == "html" then
              print("disabled")
              return true
            end

            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              vim.notify(
                "File larger than 100KB treesitter disabled for performance",
                vim.log.levels.WARN,
                { title = "Treesitter" }
              )
              return true
            end
          end,

          additional_vim_regex_highlighting = { "markdown" },
        },
      })

      -- require("nvim-treesitter.parsers").get_parser_configs().templ = {
      -- 	install_info = {
      -- 		url = "https://github.com/vrischmann/tree-sitter-templ.git",
      -- 		files = { "src/parser.c", "src/scanner.c" },
      -- 		branch = "master",
      -- 	},
      -- }
      vim.treesitter.language.register("templ", "templ")

      vim.opt.foldmethod = "expr"
      vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
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

  {
    "nvim-treesitter/nvim-treesitter-context",
    after = "nvim-treesitter",
    config = function()
      require("treesitter-context").setup({
        enable = true,            -- Enable this plugin (Can be enabled/disabled later via commands)
        multiwindow = false,      -- Enable multiwindow support.
        max_lines = 0,            -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 0,    -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true,
        multiline_threshold = 20, -- Maximum number of lines to show for a single context
        trim_scope = "outer",     -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = "cursor",          -- Line used to calculate context. Choices: 'cursor', 'topline'
        -- Separator between context and content. Should be a single character string, like '-'.
        -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
        separator = nil,
        zindex = 20,     -- The Z-index of the context window
        on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
      })
    end,
  },
}

return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "stevearc/conform.nvim",      -- Auto-formatting
    "hrsh7th/nvim-cmp",           -- Autocompletion engine
    "hrsh7th/cmp-nvim-lsp",       -- LSP source for nvim-cmp
    "hrsh7th/cmp-buffer",         -- Buffer words completion
    "hrsh7th/cmp-path",           -- Filesystem path completion
    "hrsh7th/cmp-cmdline",        -- Command line completion
    "j-hui/fidget.nvim",          -- LSP progress UI
    "williamboman/mason.nvim",    -- LSP installer/manager
    "williamboman/mason-lspconfig.nvim", -- Bridge between mason and lspconfig
    "L3MON4D3/LuaSnip",           -- Snippet engine
    "saadparwaiz1/cmp_luasnip",   -- Snippet completion for nvim-cmp
  },
  event = { "BufReadPre", "BufNewFile" }, -- Load on file open

  config = function()
    -- =====================
    -- Formatters (conform)
    -- =====================
    require("conform").setup({
      formatters_by_ft = {
        bash = { "shfmt" },
        lua = { "lua_ls" },
        python = { "ruff", "ty" },
        rust = { "rust_analyzer" },
        yaml = { "yamlls" },
      },
    })

    -- =====================
    -- Completion (nvim-cmp)
    -- =====================
    local cmp = require("cmp")
    local cmp_lsp = require("cmp_nvim_lsp")

    -- Enable LSP capabilities for autocompletion
    local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      cmp_lsp.default_capabilities()
    )
    capabilities.textDocument.semanticTokens = nil -- Performance tweak

    -- =====================
    -- Fidget (LSP progress)
    -- =====================
    require("fidget").setup({}) -- Shows LSP progress in the bottom right

    -- =====================
    -- Mason (LSP installer)
    -- =====================
    require("mason").setup()

    -- =====================
    -- Reusable on_attach function
    -- =====================
    local on_attach = function(_, bufnr)
      local opts = function(desc)
        return { buffer = bufnr, desc = desc }
      end

      -- Navigation
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("LSP: Go to definition"))
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("LSP: Go to declaration"))
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts("LSP: Go to implementation"))
      vim.keymap.set("n", "gr", vim.lsp.buf.references, opts("LSP: Find references"))
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("LSP: Hover documentation"))

      -- Actions
      vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts("LSP: Code action"))
      vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts("LSP: Rename symbol"))
      vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts("LSP: Signature help"))

      -- Diagnostics
      vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts("Diagnostic: Show line diagnostics"))
      vim.keymap.set("n", "<leader>vD", vim.diagnostic.setloclist, opts("Diagnostic: Open location list"))
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts("Diagnostic: Previous diagnostic"))
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts("Diagnostic: Next diagnostic"))

      -- Workspace
      vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts("LSP: Workspace symbols"))
    end

    -- =====================
    -- Mason-lspconfig (LSP setup)
    -- =====================
    require("mason-lspconfig").setup({
      ensure_installed = {
        "ansiblels",
        "bashls",
        "biome",
        "docker_compose_language_service",
        "dockerls",
        "lua_ls",
        "ruff",
        "rust_analyzer",
        "yamlls",
      },
      handlers = {
        function(server_name)
          require("lspconfig")[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
        -- Special cases
        zls = function()
          local lspconfig = require("lspconfig")
          lspconfig.zls.setup({
            on_attach = on_attach,
            capabilities = capabilities,
            root_dir = lspconfig.util.root_pattern(".git", "build.zig", "zls.json"),
            settings = {
              zls = {
                enable_inlay_hints = true,
                enable_snippets = true,
                warn_style = true,
              },
            },
          })
          vim.g.zig_fmt_parse_errors = 0
          vim.g.zig_fmt_autosave = 0
        end,
        ["lua_ls"] = function()
          local lspconfig = require("lspconfig")
          lspconfig.lua_ls.setup({
            on_attach = on_attach,
            capabilities = capabilities,
            settings = {
              Lua = {
                runtime = { version = "Lua 5.1" },
                diagnostics = {
                  globals = { "bit", "vim", "it", "describe", "before_each", "after_each" },
                },
              },
            },
          })
        end,
      }
    })

    -- =====================
    -- Completion setup (nvim-cmp)
    -- =====================
    local cmp_select = { behavior = cmp.SelectBehavior.Select }
    require("luasnip.loaders.from_vscode").lazy_load()
    require("luasnip.loaders.from_snipmate").lazy_load({
      paths = vim.fn.stdpath("config") .. "/snippets/"
    })

    cmp.setup({
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(), -- Show completion menu
        ["<C-x>"] = cmp.mapping.confirm({ select = true }), -- Confirm selection
        ["<C-e>"] = cmp.mapping.abort(), -- Close completion menu
        ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select), -- Previous item
        ["<C-n>"] = cmp.mapping.select_next_item(cmp_select), -- Next item
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
      }, {
        { name = "buffer" },
      }),
    })

    -- =====================
    -- Diagnostics UI
    -- =====================
    vim.diagnostic.config({
      float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
      -- Show signs in the gutter
      signs = true,
      -- Show diagnostics in the statusline
      update_in_insert = false,
    })

    -- =====================
    -- Format-on-save
    -- =====================
    local VmGroup = vim.api.nvim_create_augroup("vm", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = VmGroup,
      callback = function(args)
        require("conform").format({ bufnr = args.buf })
      end,
    })
  end
}

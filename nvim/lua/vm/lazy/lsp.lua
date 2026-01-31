return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "stevearc/conform.nvim",
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "j-hui/fidget.nvim",
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
  },
  event = { "BufReadPre", "BufNewFile" },

  config = function()
    -- =====================
    -- Formatters (conform)
    -- =====================
    require("conform").setup({
      formatters_by_ft = {
        bash = { "shfmt" },
        lua = { "lua_ls" },
        python = { "ruff" },
        rust = { "rust_analyzer" },
        yaml = { "yamlls" },
      },
    })

    -- =====================
    -- Completion (nvim-cmp)
    -- =====================
    local cmp = require("cmp")
    local cmp_lsp = require("cmp_nvim_lsp")

    local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      cmp_lsp.default_capabilities()
    )

    -- Optional performance tweak
    capabilities.textDocument.semanticTokens = nil

    -- =====================
    -- Fidget (LSP progress)
    -- =====================
    require("fidget").setup({})

    -- =====================
    -- Mason setup
    -- =====================
    require("mason").setup()

    -- =====================
    -- Reusable on_attach
    -- =====================
    local on_attach = function(_, bufnr)
      local opts = function(desc)
        return { buffer = bufnr, desc = desc }
      end

      -- LSP keymaps
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("Hover documentation"))
      vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts("Workspace symbols"))
      vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts("Show diagnostics"))
      vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts("Code action"))
      vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts("Find references"))
      vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts("Rename symbol"))
      vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts("Signature help"))

      -- Diagnostics navigation
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts("Previous diagnostic"))
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts("Next diagnostic"))
    end

    -- =====================
    -- Mason-lspconfig
    -- =====================
    require("mason-lspconfig").setup({
      ensure_installed = {
        "ansiblels",
        -- 'ansible_lint',
        "bashls",
        "biome",
        "docker_compose_language_service",
        "dockerls",
        "lua_ls",
        "ruff",
        -- "mypy",
        "rust_analyzer",
        "shellcheck",
        "shfmt",
        "yamlls",
      },
      handlers = {
        function(server_name)
          require("lspconfig")[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,

        -- Zig special case
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

        -- Lua special case
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
    -- Completion setup
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
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-x>"] = cmp.mapping.confirm({ select = true }),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
        ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
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

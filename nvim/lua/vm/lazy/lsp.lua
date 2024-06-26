return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'hrsh7th/nvim-cmp',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'j-hui/fidget.nvim',
    },
    config = function()
      local cmp = require('cmp')
      local cmp_lsp = require('cmp_nvim_lsp')
      local capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        cmp_lsp.default_capabilities()
      )

      require("fidget").setup({ notification = { window = { winblend = 0, }, } })

      require("mason").setup()
      require("mason-lspconfig").setup({
        ensured_installed = {
          'ansiblels',
          'asm_lsp',  -- Assembly
          'bashls',
          'codeqlls', -- CodeQL
          'docker_compose_language_service',
          'dockerls',
          'gopls',
          -- 'helm_ls',
          'html-lsp',
          'htmlbeautifier',
          'htmx',
          'java-test',
          'jdtls',
          'ltex',
          'lua_ls',
          'ruff_lsp', -- python
          'ruff',     -- python
          'rust_analyzer',
          'taplo',    -- taplo
          'yamlls',
          'zig',
        },
        handlers = {
          function(server_name) -- default handler (optional)
            require("lspconfig")[server_name].setup {
              capabilities = capabilities
            }
          end,
          ["lua_ls"] = function()
            local lspconfig = require("lspconfig")
            lspconfig.lua_ls.setup {
              capabilities = capabilities,
              settings = {
                Lua = {
                  diagnostics = {
                    globals = { "bit", "vim", "it", "describe" }
                  }
                }
              }
            }

            lspconfig.ruff_lsp.setup {
              init_options = {
                settings = {
                  -- Any extra CLI arguments for `ruff` go here.
                  args = {
                    "--config=./pyproject.toml",
                  },
                },
              },
            }
          end,
        }
      })

      local cmp_select = { behavior = cmp.SelectBehavior.Select }
      cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
          ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
          ['<C-x>'] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
        })
      })

      vim.diagnostic.config({
        update_in_insert = true,
        float = { focusable = false, style = "minimal", border = "rounded", source = "always", header = "", prefix = "", }
      })

      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        pattern = { "*.py" },
        desc = "Auto-format Python files after saving",
        callback = function()
          local fileName = vim.api.nvim_buf_get_name(0)
          vim.cmd(":silent !black --preview -q " .. fileName)
          vim.cmd(":silent !isort --profile black --float-to-top -q " .. fileName)
          vim.cmd(":silent !docformatter --in-place --black " .. fileName)
        end,
        group = autocmd_group,
      })

      -- vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
    end
  }
}

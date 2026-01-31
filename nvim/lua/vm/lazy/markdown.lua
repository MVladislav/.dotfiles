return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { "markdown" },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      highlight = {
        enable = true,
      },
      html = { enabled = false },
      latex = { enabled = false },
      yaml = { enabled = false },
    },
  },
}

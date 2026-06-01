return {
	"folke/trouble.nvim",
	cmd = "Trouble",
	event = "VeryLazy",
	config = function()
		require("trouble").setup({
			modes = {
				diagnostics = {
					auto_open = false,
					auto_close = true,
				},
        preview_float = {
          mode = "diagnostics",
          preview = {
            type = "float",
            relative = "editor",
            border = "rounded",
            title = "Preview",
            title_pos = "center",
            position = { 0, -2 },
            size = { width = 0.3, height = 0.3 },
            zindex = 200,
          },
        },
			},
			warn_no_results = false,
		})
	end,
  keys = {
    {
      "<leader>tt",
      "<cmd>Trouble diagnostics toggle focus=true filter.buf=0<cr>",
      desc = "Trouble: Toggle diagnostics",
    },
    {
      "<leader>tT",
      "<cmd>Trouble diagnostics toggle focus=true<cr>",
      desc = "Trouble: Toggle buffer diagnostics",
    },
    {
      "<leader>ts",
      "<cmd>Trouble symbols toggle focus=true<cr>",
      desc = "Trouble: Toggle symbols",
    },
    {
      "<leader>tq",
      "<cmd>Trouble qflist toggle focus=true<cr>",
      desc = "Trouble: Toggle quickfix list",
    },
  },
}

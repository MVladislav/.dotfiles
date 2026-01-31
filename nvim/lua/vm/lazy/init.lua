return {
  {
    'nvim-lua/plenary.nvim',
    lazy = true,
  },
  {
    'eandrju/cellular-automaton.nvim',
    keys = {
      { "<leader>fml1", "<cmd>CellularAutomaton make_it_rain<CR>" },
      { "<leader>fml2", "<cmd>CellularAutomaton game_of_life<CR>" },
    },
  },
}

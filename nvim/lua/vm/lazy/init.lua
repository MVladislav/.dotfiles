return {
  {
    'nvim-lua/plenary.nvim'
  },
  {
    'eandrju/cellular-automaton.nvim',
    config = function()
      vim.keymap.set('n', '<leader>fml1', "<cmd>CellularAutomaton make_it_rain<CR>")
      vim.keymap.set('n', '<leader>fml2', "<cmd>CellularAutomaton game_of_life<CR>")
    end
  },
}

return {
  {
    "ducks/vimdeck.nvim",
    cmd = { "Vimdeck", "VimdeckFile" },
    ft = "markdown",
    opts = {
      use_figlet = false,
    },
    keys = {
      { "<leader>mp", "<cmd>Vimdeck<CR>", ft = "markdown", desc = "Present markdown" },
    },
  },
}

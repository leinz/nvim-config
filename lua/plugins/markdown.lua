return {
  {
    "ducks/vimdeck.nvim",
    cmd = { "Vimdeck", "VimdeckFile" },
    ft = "markdown",
    opts = {
      use_figlet = false,
      header_style = "underline",
      center_vertical = false,
    },
    config = function(_, opts)
      require("config.vimdeck").setup(opts)
    end,
    keys = {
      { "<leader>mp", "<cmd>Vimdeck<CR>", ft = "markdown", desc = "Present markdown" },
    },
  },
}

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
    },
    opts = {
      format_on_save = function(bufnr)
        local disabled = vim.b[bufnr].disable_autoformat
        if disabled then
          return
        end
        return { timeout_ms = 1500, lsp_fallback = true }
      end,
      formatters_by_ft = {
        go = { "gofmt", "goimports" },
        java = { "google-java-format" },
        markdown = { "prettier" },
        python = { "ruff_format", "ruff_organize_imports" },
        rust = { "rustfmt" },
      },
    },
  },
}

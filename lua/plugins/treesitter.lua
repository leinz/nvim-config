local disabled_langs = {
  lua = true,
  markdown = true,
  markdown_inline = true,
}

vim.treesitter.query.set("lua", "highlights", "")

local function parser_can_parse(buf, lang)
  return pcall(function()
    local parser = vim.treesitter.get_parser(buf, lang)
    parser:parse()
  end)
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    opts = {
      install_dir = vim.fn.stdpath("data") .. "/site",
    },
    config = function(_, opts)
      local ok, treesitter = pcall(require, "nvim-treesitter")
      if not ok then
        return
      end

      treesitter.setup(opts)

      local group = vim.api.nvim_create_augroup("config_treesitter", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(args.match) or args.match
          if disabled_langs[lang] then
            return
          end

          if not parser_can_parse(args.buf, lang) then
            return
          end

          local ok = pcall(vim.treesitter.start, args.buf, lang)
          if ok then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}

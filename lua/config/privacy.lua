-- Privacy-oriented defaults: avoid writing buffer contents, command history,
-- registers, marks, and searches into Neovim side files.
local opt = vim.opt

opt.shadafile = "NONE"
opt.shada = ""
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.undofile = false

-- Avoid trusting project-local config or file-provided modelines by default.
opt.exrc = false
opt.secure = true
opt.modeline = false
opt.modelines = 0

-- Do not integrate with the OS clipboard unless you opt in manually.
opt.clipboard = ""

-- Keep logs intentionally small.
if vim.lsp.log and vim.lsp.log.set_level then
  pcall(vim.lsp.log.set_level, "off")
else
  pcall(vim.lsp.set_log_level, "off")
end

-- Disable built-in network file browsing plugins. Normal local netrw browsing
-- remains available if you remove these lines.
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

vim.api.nvim_create_user_command("PrivacyStatus", function()
  local lines = {
    "Privacy settings:",
    "  shadafile=" .. tostring(vim.o.shadafile),
    "  swapfile=" .. tostring(vim.o.swapfile),
    "  backup=" .. tostring(vim.o.backup),
    "  writebackup=" .. tostring(vim.o.writebackup),
    "  undofile=" .. tostring(vim.o.undofile),
    "  modeline=" .. tostring(vim.o.modeline),
    "  clipboard=" .. (vim.o.clipboard == "" and "<empty>" or vim.o.clipboard),
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, {})

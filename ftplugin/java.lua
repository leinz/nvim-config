local ok, jdtls = pcall(require, "jdtls")
if not ok then
  return
end

local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "settings.gradle" }
local root_dir = require("jdtls.setup").find_root(root_markers)
if not root_dir then
  return
end

local project_name = vim.fn.fnamemodify(root_dir, ":t")
if project_name == "" then
  project_name = "workspace"
end
local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspaces/" .. project_name

local mason_jdtls = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
local launcher = vim.fn.glob(mason_jdtls .. "/plugins/org.eclipse.equinox.launcher_*.jar")
local config_dir = mason_jdtls .. "/config_mac"

if vim.fn.has("linux") == 1 then
  config_dir = mason_jdtls .. "/config_linux"
elseif vim.fn.has("win32") == 1 then
  config_dir = mason_jdtls .. "/config_win"
end

if launcher == "" then
  vim.notify("jdtls is not installed. Run :MasonInstall jdtls", vim.log.levels.WARN)
  return
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
local has_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if has_cmp then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

local on_attach = function(_, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  map("n", "gd", vim.lsp.buf.definition, "Go to definition")
  map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  map("n", "gr", vim.lsp.buf.references, "Find references")
  map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
  map("n", "K", vim.lsp.buf.hover, "Hover documentation")
  map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
  map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
end

jdtls.start_or_attach({
  cmd = {
    "java",
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=false",
    "-Dlog.level=OFF",
    "-Xms1g",
    "--add-modules=ALL-SYSTEM",
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",
    "-jar",
    launcher,
    "-configuration",
    config_dir,
    "-data",
    workspace_dir,
  },
  capabilities = capabilities,
  on_attach = on_attach,
  root_dir = root_dir,
  settings = {
    java = {
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" },
      completion = { favoriteStaticMembers = {} },
      sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
    },
  },
})

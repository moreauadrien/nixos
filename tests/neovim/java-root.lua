-- Run from the repository root: nvim --headless -u NONE -l tests/neovim/java-root.lua
-- Load the real LSP configuration without downloading plugins or starting servers.
vim.pack.add = function() end
vim.lsp.enable = function() end
package.loaded.fidget = { setup = function() end }
package.loaded['java-debug-paths'] = { bundles = {} }
package.loaded['jdtls.capabilities'] = {}
package.loaded['kickstart.java-runtime'] = {}
dofile 'modules/features/neovim/config/lua/kickstart/plugins/lspconfig.lua'

local dir = vim.fn.tempname()
vim.fn.mkdir(dir .. '/src/main/java', 'p')
vim.fn.writefile({}, dir .. '/pom.xml')
local source = dir .. '/src/main/java/Main.java'
vim.fn.writefile({ 'class Main {}' }, source)
local markers = vim.lsp.config.jdtls.root_markers
assert(vim.fs.root(source, markers) == dir, 'Maven project without Git or mvnw must have a root')
vim.fn.delete(dir .. '/pom.xml')
for _, marker in ipairs { '.git', 'gradlew', 'mvnw' } do
  vim.fn.writefile({}, dir .. '/' .. marker)
  assert(vim.fs.root(source, markers) == dir, 'Existing marker must still work: ' .. marker)
  vim.fn.delete(dir .. '/' .. marker)
end
vim.fn.delete(dir, 'rf')
print('PASS: Java project root detection (4 cases)')

-- devenv exports JAVA_HOME; the JDK's release file identifies its Java version.
local home = vim.env.JAVA_HOME
if not home or home == '' then return {} end

local release = io.open(home .. '/release', 'r')
local contents = release and release:read '*a' or ''
if release then release:close() end
local version = contents:match('JAVA_VERSION="([^"]+)"')
local major = version and (version:match '^1%.(%d+)' or version:match '^(%d+)')
if not major or vim.fn.executable(home .. '/bin/java') ~= 1 then
  vim.notify('Invalid JAVA_HOME: start Neovim inside the project\'s devenv shell with a valid JDK.', vim.log.levels.WARN)
  return {}
end

local name = tonumber(major) <= 8 and ('JavaSE-1.' .. major) or ('JavaSE-' .. major)
return {
  configuration = {
    runtimes = {
      { name = name, path = home, default = true },
    },
  },
}

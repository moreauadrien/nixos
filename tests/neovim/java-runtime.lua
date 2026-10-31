-- Run from the repository root: luajit tests/neovim/java-runtime.lua
local module = 'modules/features/neovim/config/lua/kickstart/java-runtime.lua'
local open = io.open
local function check(home, release, executable, expected, warns)
  local warnings = 0
  local closed = false
  vim = {
    env = { JAVA_HOME = home },
    fn = { executable = function(path)
      assert(path == home .. '/bin/java')
      return executable
    end },
    log = { levels = { WARN = 2 } },
    notify = function() warnings = warnings + 1 end,
  }
  io.open = function(path)
    assert(path == home .. '/release')
    if not release then return nil end
    return {
      read = function() return release end,
      close = function() closed = true end,
    }
  end
  local settings = dofile(module)
  io.open = open
  assert(warnings == (warns and 1 or 0))
  if release then assert(closed) end
  if expected then
    local runtime = settings.configuration.runtimes[1]
    assert(runtime.name == expected)
    assert(runtime.path == home)
    assert(runtime.default == true)
  else
    assert(next(settings) == nil)
  end
end

check(nil, nil, 0)
check('', nil, 0)
check('/jdk8', 'JAVA_VERSION="1.8.0_442"', 1, 'JavaSE-1.8')
check('/jdk17', 'JAVA_VERSION="17.0.14"', 1, 'JavaSE-17')
check('/jdk21', 'JAVA_VERSION="21.0.6"', 1, 'JavaSE-21')
check('/jdk25', 'JAVA_VERSION="25-ea"', 1, 'JavaSE-25')
check('/invalid', nil, 0, nil, true)
check('/invalid', 'JAVA_VERSION="unknown"', 1, nil, true)
check('/missing-java', 'JAVA_VERSION="21"', 0, nil, true)
print('PASS: devenv Java runtime detection (9 cases)')

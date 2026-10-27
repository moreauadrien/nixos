------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

require("apps")
require("autostart")
require("permissions")
require("looknfeel")
require("input")
require("bindings")
require("workspaces")

-- hyprmoncfg creates this file on its first profile application.
-- Load it last, when present, so generated rules override the defaults.
local monitorsPath = (os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")) .. "/hypr/hyprmoncfg-monitors.lua"
local f = io.open(monitorsPath, "r")
if f then
    f:close()
    dofile(monitorsPath)
end

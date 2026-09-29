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

-- hyprmoncfg generates monitors.lua when it applies a profile (TUI or
-- hyprmoncfgd), so the file may not exist yet when Hyprland parses this
-- config at startup. Only require it if present: until then the default
-- monitor config above applies, and hyprmoncfgd writes + applies the
-- profile live once it starts. A plain require() of a missing module is
-- reported as a config error (popup at startup).
local monitorsPath = (os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")) .. "/hypr/monitors.lua"
local f = io.open(monitorsPath, "r")
if f then
    f:close()
    require("monitors")
end

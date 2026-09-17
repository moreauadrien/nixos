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

hl.monitor({
  output = "Virtual-1",
  mode = "3840x2160@60.00",
  position = "0x0",
  scale = 2,
  sdr_min_luminance = 0.2,
  sdr_max_luminance = 80,
})

require("apps")
require("autostart")
require("permissions")
require("looknfeel")
require("input")
require("bindings")
require("workspaces")

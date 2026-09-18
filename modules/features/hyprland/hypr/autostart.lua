hl.on("hyprland.start", function () 
  hl.exec_cmd("elephant") -- backend required by walker
  hl.exec_cmd("walker --gapplication-service")
  hl.exec_cmd("qs")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("mako")
end)

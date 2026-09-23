# Hyprpaper wallpaper daemon.
{
  flake.nixosModules.hyprpaper = {pkgs, ...} : {
    hjem.users.adrien = {
      packages = [ pkgs.hyprpaper ];
      files.".config/hypr/hyprpaper.conf".text = ''
        wallpaper {
            monitor =
            path = ~/.config/wallpapers/the-backwater.jpg
        }

        splash = false
      '';
    };
  };
}

# Hyprpaper wallpaper daemon.
{ pkgs, ... }: {
  flake.nixosModules.hyprpaper = {
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

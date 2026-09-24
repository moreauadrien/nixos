# Hyprpaper wallpaper daemon.
# The image comes from the wallpaper module (nix store path).
{
  ...
}: {
  flake.nixosModules.hyprpaper = { config, pkgs, ... } : {
    hjem.users.adrien = {
      packages = [ pkgs.hyprpaper ];
      files.".config/hypr/hyprpaper.conf".text = ''
        wallpaper {
            monitor =
            path = ${config.wallpaper.path}
        }

        splash = false
      '';
    };
  };
}

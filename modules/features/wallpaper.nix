# Wallpaper: the image lives in the nix store, exposed as a read-only path.
# Other features (hyprpaper, hyprlock, ...) read `config.wallpaper.path`
# instead of hard-coding relative paths into their configs.
{
  flake.nixosModules.wallpaper = { lib, config, ... }: {
    options.wallpaper = {
      file = lib.mkOption {
        type = lib.types.path;
        description = ''
          Wallpaper image added to the nix store. Change it here once and every
          consumer (hyprpaper, hyprlock, ...) follows automatically.
        '';
      };

      path = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Absolute path of the wallpaper in the nix store.";
      };
    };

    config.wallpaper = {
      file = ./wallpapers/the-backwater.jpg;
      path = "${config.wallpaper.file}";
    };
  };
}

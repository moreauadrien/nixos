# Hyprland session: compositor + greetd login (tuigreet starts Hyprland).
# Owns its own config (./hypr): the config defines its binaries,
# so importing this module alone yields a complete session.
{ ... }: {
  flake.nixosModules.hyprland = { pkgs, ... }: {
    programs.hyprland.enable = true;

    hjem.users.adrien.files = let
      # individual links: the daemon configs (hyprpaper/hypridle/hyprsunset)
      # live in their own feature modules and complete this directory
      hyprFiles = [
        "hyprland.lua"
        "autostart.lua"
        "bindings.lua"
        "looknfeel.lua"
        "apps.lua"
        "workspaces.lua"
        "input.lua"
        "permissions.lua"
        "hyprlock.conf"
      ];
    in {
      ".config/wallpapers".source = ./wallpapers;
    } // builtins.listToAttrs (map (f: {
      name = ".config/hypr/${f}";
      value.source = ./hypr + "/${f}";
    }) hyprFiles);

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --remember --time --cmd start-hyprland";
        };
        initial_session = {
          command = "start-hyprland";
          user = "adrien";
        };
      };
    };
  };
}

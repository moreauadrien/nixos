# Hyprland session: compositor + greetd login (tuigreet starts Hyprland).
# Owns its own config (./hypr): the config defines its binaries,
# so importing this module alone yields a complete session.
{ self, ... }: {
  flake.nixosModules.hyprland = { pkgs, lib, ... }: {
    imports = with self.nixosModules; [
      wallpaper
      hyprpaper
      hypridle
      hyprlock
    ];

    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

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
      ];
    in builtins.listToAttrs (map (f: {
      name = ".config/hypr/${f}";
      value.source = ./hypr + "/${f}";
    }) hyprFiles);

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --remember --time --cmd \"uwsm start hyprland-uwsm.desktop\"";
        };
        initial_session = {
          command = "uwsm start hyprland-uwsm.desktop";
          user = "adrien";
        };
      };
    };
  };
}

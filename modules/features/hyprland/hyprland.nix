# Hyprland session: compositor + greetd login (tuigreet starts Hyprland).
# Owns its own config (./hypr): the config defines its binaries,
# so importing this module alone yields a complete session.
{ ... }: {
  flake.nixosModules.hyprland = { pkgs, ... }: {
    programs.hyprland.enable = true;

    hjem.users.adrien.files = {
      ".config/hypr".source = ./hypr;
      ".config/mako/config".source = ./mako/config;
      # wallpapers are referenced by hypr/hyprpaper.conf
      ".config/wallpapers".source = ./wallpapers;
    };

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

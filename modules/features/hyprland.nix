# Hyprland session: compositor + greetd login (tuigreet starts Hyprland).
# Owns its own dotfiles (dotfiles/hypr): the config defines its binaries,
# so importing this module alone yields a complete session.
{ self, ... }: {
  flake.nixosModules.hyprland = { pkgs, ... }: {
    programs.hyprland.enable = true;

    hjem.users.adrien.files = {
      ".config/hypr".source = "${self}/dotfiles/hypr";
      # wallpapers are referenced by dotfiles/hypr/hyprpaper.conf
      ".config/wallpapers".source = "${self}/dotfiles/wallpapers";
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

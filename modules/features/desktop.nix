{ self, inputs, ... }: {
  flake.nixosModules.desktop =
    { lib, pkgs, ... }:
    {
      programs.hyprland = {
        enable = true;
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

      hjem.users.adrien = {
        packages = [ pkgs.notwaita-cursor ];
        files = {
          ".icons".source = "${pkgs.notwaita-cursor}/share/icons";
          ".config/hypr".source = "${self}/dotfiles/hypr";
          ".config/wallpapers".source = "${self}/dotfiles/wallpapers";
          ".config/quickshell".source = "${self}/dotfiles/quickshell";
          ".config/alacritty".source = "${self}/dotfiles/alacritty";
        };
      };

      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        ubuntu-sans
      ];

      fonts.fontconfig.defaultFonts = {
        serif = [ "Ubuntu Sans" ];
        sansSerif = [ "Ubuntu Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
      };

      environment.sessionVariables = {
        XCURSOR_THEME = "Notwaita-Black";
        XCURSOR_SIZE = "20";
      };

      environment.systemPackages = [
        pkgs.hyprmoncfg
        pkgs.hyprpaper
        pkgs.alacritty
        pkgs.brightnessctl
        pkgs.playerctl
        pkgs.quickshell
        pkgs.bluetui
      ];
    };
}

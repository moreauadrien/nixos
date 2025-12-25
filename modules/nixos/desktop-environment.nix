{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  services.displayManager = {
    autoLogin.user = "adrien";
    autoLogin.enable = true;
    gdm = {
      enable = true;
      wayland = true;
    };
  };

  programs.hyprlock.enable = true;
  services.hypridle.enable = true;

  environment.systemPackages = with pkgs;
    [
      alacritty
      hyprpolkitagent
      hyprpaper
      dunst
      rofi
      nautilus
      xdg-desktop-portal-hyprland
      waybar
      wl-clipboard
      slurp
      grim

      hyprcursor
      xcursor-themes
      bibata-cursors

      vlc
      eog
    ]
    ++ lib.optionals config.services.tailscale.enable [
      pkgs.trayscale
    ];

  programs.firefox.enable = true;
  programs.gnome-disks.enable = true;
}

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
    sddm = {
      enable = true;
      wayland.enable = true;
    };

    autoLogin = {
      enable = true;
      user = "adrien";
    };
  };

  programs.hyprlock.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  environment.systemPackages = with pkgs;
    [
      alacritty
      hyprpolkitagent
      hyprpaper
      rofi
      nautilus
      xdg-desktop-portal-hyprland
      waybar
      xwayland

      hyprdynamicmonitors

      slurp
      grim
      gradia

      hyprcursor

      eog
    ]
    ++ lib.optionals config.services.tailscale.enable [
      pkgs.trayscale
    ];

  programs.gnome-disks.enable = true;
}

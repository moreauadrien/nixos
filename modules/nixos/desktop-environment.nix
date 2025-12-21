{
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


  #services.displayManager.sddm = {
  #  enable = true;
  #  wayland.enable = true;
  #};

  services.displayManager = {
    autoLogin.user = "adrien";
    autoLogin.enable = true;
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };


  programs.hyprlock.enable = true;

  environment.systemPackages = with pkgs; [
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

    xcursor-themes
    bibata-cursors
  ];
}

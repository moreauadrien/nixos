{
  inputs,
  pkgs,
  ...
}: {
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    withUWSM = true;
  };

  services.displayManager.gdm.enable = true;

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
    xcursor-themes
    slurp
    grim
  ];
}

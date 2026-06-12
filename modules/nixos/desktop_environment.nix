{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  programs.hyprland.enable = true;

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

  environment.systemPackages = with pkgs;
    [
      alacritty
      hyprpolkitagent
      hyprpaper
      nautilus
      xdg-desktop-portal-hyprland
      waybar
      xwayland
      hyprsunset
      wl-clipboard

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


  services.hyprdynamicmonitors = {
    enable = true;
    mode = "user";

    configFile = ../../dotfiles/hyprdynamicmonitors/config.toml;

    extraFiles = {
      "xdg/hyprdynamicmonitors/hyprconfigs" = ../../dotfiles/hyprdynamicmonitors/hyprconfigs;
    };

    extraFlags = [ "--enable-lid-events" "--debug" ];
  };

  services.upower.enable = true;
}

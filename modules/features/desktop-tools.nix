# Desktop utilities shipped system-wide.
{ ... }: {
  flake.nixosModules.desktop-tools = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      hyprmoncfg
      hyprpaper
      brightnessctl
      playerctl
      bluetui
      walker
      elephant
      mako
      # Referenced by the hyprland config (bindings, idle daemon, night light):
      # install them here so the configs can never point at a missing binary.
      hyprlock
      hypridle
      hyprsunset
      gradia
    ];
  };
}

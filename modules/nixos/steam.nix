{pkgs, ...}: {
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    extest.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gamescope
    mangohud
    protonup-qt
    lutris
    heroic
  ];

  hardware.graphics.enable32Bit = true;

  programs.gamemode.enable = true;
}

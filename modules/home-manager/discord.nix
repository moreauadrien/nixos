{
  pkgs,
  lib,
  ...
}: let
  discordLauncher = pkgs.makeDesktopItem {
    name = "discord";
    desktopName = "Discord";
    exec = "${pkgs.chromium}/bin/chromium --app=https://discord.com/app--class=Discord";
    #icon = "chromium";
    #categories = [ "Network" ];
  };
in {
  home.packages = [discordLauncher];
}

{
  pkgs,
  lib,
  ...
}: let
  spotifyLauncher = pkgs.makeDesktopItem {
    name = "spotify";
    desktopName = "Spotify";
    exec = "${pkgs.chromium}/bin/chromium --app=https://open.spotify.com --class=Spotify";
    #icon = "chromium";
    #categories = [ "Network" ];
  };
in {
  home.packages = [spotifyLauncher];
}

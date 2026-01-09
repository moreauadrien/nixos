{
  pkgs,
  lib,
  ...
}: let
  whatsappLauncher = pkgs.makeDesktopItem {
    name = "whatsapp";
    desktopName = "Whatsapp";
    exec = "${pkgs.ungoogled-chromium}/bin/chromium --app=https://web.whatsapp.com --class=Whatsapp";
    #icon = "chromium";
    #categories = [ "Network" ];
  };
in {
  home.packages = [whatsappLauncher];
}

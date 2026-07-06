{
  pkgs,
  lib,
  ...
}: let
  whatsappIcon = pkgs.fetchurl {
    url = "https://cdn-icons-png.flaticon.com/512/124/124034.png";
    hash = "sha256-dM+E8278XoHzXWSyvYJ4Bvo+X59cr8fCPSdTg2UEkLs=";
  };

  whatsappLauncher = pkgs.makeDesktopItem {
    name = "whatsapp";
    desktopName = "Whatsapp";
    exec = "${pkgs.ungoogled-chromium}/bin/chromium --app=https://web.whatsapp.com --class=Whatsapp";
    icon = whatsappIcon;
  };
in {
  home.packages = [whatsappLauncher];
}

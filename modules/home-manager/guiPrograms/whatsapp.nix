{
  pkgs,
  lib,
  ...
}: let
  whatsappIcon = pkgs.fetchurl {
    url = "https://cdn-icons-png.flaticon.com/512/124/124034.png";
    hash = lib.fakeHash;  # Remplacer par le vrai hash après la première exécution
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

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

      # Applications
      signal-desktop
      localsend
      eog
      evince
      gimp
      libreoffice
      btop
      file-roller

      # WhatsApp = web app in a dedicated chromium window
      ungoogled-chromium
      (pkgs.makeDesktopItem {
        name = "whatsapp";
        desktopName = "Whatsapp";
        exec = "${pkgs.ungoogled-chromium}/bin/chromium --app=https://web.whatsapp.com --class=Whatsapp";
        icon = pkgs.fetchurl {
          url = "https://cdn-icons-png.flaticon.com/512/124/124034.png";
          hash = "sha256-dM+E8278XoHzXWSyvYJ4Bvo+X59cr8fCPSdTg2UEkLs=";
        };
      })
    ];
  };
}

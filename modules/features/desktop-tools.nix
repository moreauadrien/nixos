# Desktop utilities shipped system-wide.
{ ... }: {
  flake.nixosModules.desktop-tools = { pkgs, ... }: {
    # BlueZ daemon: bluetui talks to it over D-Bus (org.bluez).
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    environment.systemPackages = with pkgs; [
      hyprmoncfg
      brightnessctl
      playerctl
      bluetui
      walker
      elephant
      # Referenced by the hypridle config (lock on idle):
      # install it here so the config can never point at a missing binary.
      hyprlock

      grim
      slurp
      gradia

      # Applications
      eog
      evince
      btop
      file-roller
      nautilus

      # User Applications
      localsend
      signal-desktop
      gimp
      libreoffice
      spotify

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

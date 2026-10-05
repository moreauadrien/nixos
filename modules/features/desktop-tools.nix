# Desktop utilities shipped system-wide.
{ moduleWithSystem, ... }: {
  flake.nixosModules.desktop-tools = moduleWithSystem ({ pkgs, ... }: {
    # Spotify: force native Wayland (ozone). Under XWayland the bundled Chromium
    # ignores XCURSOR_THEME and renders a default cursor; the nixpkgs wrapper
    # unsets DISPLAY when NIXOS_OZONE_WL=1, which makes the cursor theme work.
    # The desktop entry Exec is repointed at the wrapper so launchers (walker)
    # also start it on Wayland.
    # Built with the NixOS pkgs instance (not perSystem.packages): spotify is
    # unfree and perSystem pkgs have no allowUnfree config, which would break
    # `nix flake show` / `nix eval .#packages` for the whole flake.

    # Folders must open in nautilus (walker opens entries via xdg-open),
    # otherwise chromium claims them by default. Merges with the browser
    # mime defaults set in librewolf.nix.
    # gio reports bind mounts (preservation dirs) as inode/mount-point,
    # not inode/directory: without a default, xdg-open falls back to its
    # BROWSER list (chromium) for those.
    xdg.mime.defaultApplications = {
      "inode/directory" = "org.gnome.Nautilus.desktop";
      "inode/mount-point" = "org.gnome.Nautilus.desktop";
    };

    # BlueZ daemon: bluetui talks to it over D-Bus (org.bluez).
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    programs.localsend.enable = true;

    environment.systemPackages = with pkgs; [
      # Spotify, forced native Wayland (see comment above):
      (symlinkJoin {
        name = "spotify-wl";
        paths = [ spotify ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          rm $out/bin/spotify
          makeShellWrapper ${spotify}/share/spotify/spotify $out/bin/spotify \
            --set NIXOS_OZONE_WL 1
          substituteInPlace $out/share/applications/spotify.desktop \
            --replace-fail "Exec=spotify" "Exec=$out/bin/spotify"
        '';
      })

      hyprmoncfg
      brightnessctl
      playerctl
      bluetui
      walker
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
      signal-desktop
      gimp
      libreoffice

      thunderbird

      yt-dlp

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
  });
}

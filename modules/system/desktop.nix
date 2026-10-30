# Desktop profile: composes the always-on desktop features.
{ self, ... }: {
  flake.nixosModules.desktop = {
    # Power state over D-Bus: used by hyprmoncfg (lid/AC profiles)
    # and the quickshell PowerWidget.
    services.upower.enable = true;


    imports = with self.nixosModules; [
      core
      hyprland
      fonts
      cursor
      gtk-theme
      desktop-tools
      audio
      quickshell
      ghostty
      alacritty
      foot
      librewolf
      tailscale
      voxtype
      virt-manager
      obs-studio
      vlc

      speaker-fix-940xfg
    ];
  };
}

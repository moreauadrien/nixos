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
      alacritty
      mako
      librewolf
      tailscale
      voxtype

      speaker-fix-940xfg
    ];
  };
}

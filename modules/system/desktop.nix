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
      desktop-tools
      pipewire
      quickshell
      alacritty
      librewolf
      tailscale
      voxtype
    ];
  };
}

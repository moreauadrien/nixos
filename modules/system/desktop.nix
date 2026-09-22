{ self, ... }: {
  flake.nixosModules.desktop = {
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

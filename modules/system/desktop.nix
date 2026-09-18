{ self, ... }: {
  flake.nixosModules.desktop = {
    imports = with self.nixosModules; [
      core
      hyprland
      fonts
      cursor
      desktop-tools
      quickshell
      alacritty
    ];
  };
}

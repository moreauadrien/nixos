# Alacritty terminal: binary + its config (self-contained feature).
{ self, ... }: {
  flake.nixosModules.alacritty = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.alacritty ];

    hjem.users.adrien.files.".config/alacritty".source = "${self}/dotfiles/alacritty";
  };
}

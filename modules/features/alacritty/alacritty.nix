# Alacritty terminal: binary + its config (self-contained feature).
{ ... }: {
  flake.nixosModules.alacritty = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.alacritty ];

    hjem.users.adrien.files.".config/alacritty".source = ./config;
  };
}

# Ghostty terminal: binary + its config (self-contained feature).
{ ... }: {
  flake.nixosModules.ghostty = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.ghostty ];

    hjem.users.adrien.files.".config/ghostty".source = ./config;
  };
}
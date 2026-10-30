# Backup terminal with upstream defaults.
{ ... }: {
  flake.nixosModules.ghostty = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.ghostty ];
  };
}
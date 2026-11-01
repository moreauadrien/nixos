{
  flake.nixosModules.sesh = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.sesh ];
  };
}

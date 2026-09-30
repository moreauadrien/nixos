# Base network
{ ... }: {
  flake.nixosModules.network = {
    networking.networkmanager.enable = true;
  };
}

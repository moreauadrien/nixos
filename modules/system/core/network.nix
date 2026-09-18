# Base network: NetworkManager and SSH.
{ ... }: {
  flake.nixosModules.network = {
    networking.networkmanager.enable = true;
    services.openssh.enable = true;
  };
}

{ ... }: {
  flake.nixosModules.orbitConfiguration = {
    networking.hostName = "orbit";

    wsl.enable = true;
    wsl.defaultUser = "adrien";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    system.stateVersion = "26.05";
  };
}

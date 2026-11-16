# Host orbit: WSL without the desktop or physical-machine profiles.
{ self, inputs, ... }: {
  flake.nixosConfigurations.orbit = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      inputs.nixos-wsl.nixosModules.default
      inputs.hjem.nixosModules.default
      self.nixosModules.orbitConfiguration
      self.nixosModules.dev
    ];
  };
}

{ self, inputs, ... }: {
  flake.nixosConfigurations.tallyho = inputs.nixpkgs.lib.nixosSystem {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      overlays = [ self.overlays.default ];
    };
    modules = [
      inputs.disko.nixosModules.disko
      inputs.preservation.nixosModules.default
      inputs.hjem.nixosModules.default

      self.nixosModules.tallyhoConfiguration
      self.nixosModules.tallyhoDisko
      self.nixosModules.tallyhoPreservation
    ];
  };
}

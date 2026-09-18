# Host tallyho: selects shared modules and wires the external ones.
{ self, inputs, ... }: {
  flake.nixosConfigurations.tallyho = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.disko.nixosModules.disko
      inputs.preservation.nixosModules.default
      inputs.hjem.nixosModules.default

      self.nixosModules.tallyhoConfiguration
      self.nixosModules.tallyhoDisko
      self.nixosModules.tallyhoHardware
      self.nixosModules.tallyhoPreservation

      # System: desktop profile imports core and the desktop features
      self.nixosModules.desktop

      # Features
      self.nixosModules.plymouth
      self.nixosModules.pi
    ];
  };
}

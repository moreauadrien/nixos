# Core system base: always-on modules every host imports.
{ self, ... }: {
  flake.nixosModules.core = {
    imports = with self.nixosModules; [
      user
      locale
      network
      nix
      boot
    ];
  };
}

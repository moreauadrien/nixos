# Boot loader (disk layout itself lives in the host's disko module).
{ ... }: {
  flake.nixosModules.boot = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}

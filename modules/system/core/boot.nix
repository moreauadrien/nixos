# Boot loader (disk layout itself lives in the host's disko module).
{ ... }: {
  flake.nixosModules.boot = {
    boot.loader.grub.enable = true;
  };
}

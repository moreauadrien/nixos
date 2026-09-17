{ self, input, ... }: {
  flake.nixosModules.tallyhoHardware =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:

    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      boot.initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "virtio_pci"
        "sr_mod"
        "virtio_blk"
        "virtio_gpu"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [
        "kvm-intel"
        "virtio_gpu"
      ];

      hardware.graphics.enable = true;
      boot.extraModulePackages = [ ];

      swapDevices = [ ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
}

{ ... }: {
  flake.nixosModules.plymouth = { ... }: {
    boot.initrd.systemd.enable = true;
    boot.plymouth.enable = true;
    boot.kernelParams = [ "quiet" ];

    # Load the GPU driver in initrd so plymouth sees all DRM connectors
    # (e.g. external USB-C display), not just the simpledrm framebuffer
    # of the internal panel. Merges with the host's initrd kernelModules.
    boot.initrd.kernelModules = [ "i915" ];
  };
}
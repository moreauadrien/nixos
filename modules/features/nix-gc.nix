# Automatic garbage collection of NixOS generations and store paths.
{ ... }: {
  flake.nixosModules.nix-gc = {
    # Run the garbage collector weekly, removing old generations.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # Deduplicate identical store paths.
    nix.optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };

    # Keep the boot menu from filling up with old generations.
    boot.loader.systemd-boot.configurationLimit = 10;
  };
}
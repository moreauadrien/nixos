# Automatic NixOS upgrades: rebuild and switch on a schedule.
# Builds the local flake (/home/adrien/nixos), refreshing the lock file first
# so nixpkgs and the other inputs stay up to date.
{ ... }: {
  flake.nixosModules.auto-upgrade = {
    system.autoUpgrade = {
      enable = true;
      flake = "/home/adrien/nixos";
      # Refresh flake.lock before each upgrade (updates every input).
      flags = [ "--recreate-lock-file" ];
      # Daily at 04:00 (+ random delay so we don't hammer the cache).
      dates = "04:00";
      randomizedDelaySec = "45min";
      # Run the missed upgrade at boot if the machine was off at 04:00.
      persistent = true;
      # No automatic reboot: upgrades apply on next reboot.
      allowReboot = false;
    };
  };
}
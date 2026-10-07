# Automatic NixOS upgrades: rebuild and switch on a schedule.
# A pre-step refreshes flake.lock (`nix flake update`) before the rebuild so
# nixpkgs and the other inputs stay up to date.
#
# Why not the old wiki recipe (`flags = [ "--update-input" "nixpkgs" ]` or
# `--recreate-lock-file`)? Those `nix build` flags are deprecated and have
# been removed (nixos-rebuild-ng rejects them outright). Upstream has no
# option for this yet:
# https://github.com/NixOS/nixpkgs/issues/349734
# So we run `nix flake update` ourselves just before the upgrade service.
{ moduleWithSystem, ... }: {
  flake.nixosModules.auto-upgrade = moduleWithSystem ({ pkgs, ... }: {
    system.autoUpgrade = {
      enable = true;
      flake = "/home/adrien/nixos/main";
      flags = [
        "--print-build-logs"
      ];
      # Daily at 04:00 (+ random delay so we don't hammer the cache).
      dates = "04:00";
      randomizedDelaySec = "45min";
      # Run the missed upgrade at boot if the machine was off at 04:00.
      persistent = true;
      # No automatic reboot: upgrades apply on next reboot.
      allowReboot = false;
    };

    # Refresh flake.lock (all inputs) and commit it before rebuilding.
    # No `-` prefix on ExecStartPre: if the update fails (e.g. network down),
    # the upgrade is aborted rather than silently upgrading with a stale lock.
    systemd.services.nixos-upgrade.serviceConfig.ExecStartPre =
      pkgs.writeShellScript "nixos-upgrade-update-lock" ''
        set -e
        cd /home/adrien/nixos/main
        # Root commits into adrien's repo; git needs an identity for that.
        export GIT_AUTHOR_NAME="NixOS auto-upgrade"
        export GIT_AUTHOR_EMAIL="adrien@localhost"
        export GIT_COMMITTER_NAME="NixOS auto-upgrade"
        export GIT_COMMITTER_EMAIL="adrien@localhost"
        # No-op (exit 0) when the lock is already up to date.
        nix flake update --commit-lock-file
      '';

    environment.etc."gitconfig".text = ''
      [safe]
        directory = /home/adrien/nixos
        directory = /home/adrien/nixos/main
    '';
  });
}
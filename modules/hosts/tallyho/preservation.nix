{ self, inputs, ... }: {
  flake.nixosModules.tallyhoPreservation = {
    # /etc/machine-id is persistent (bind-mounted from /persistent), so
    # systemd-machine-id-commit.service fails on every boot ("not on a
    # temporary file system"). Harmless → mask it.
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    preservation = {
      enable = true;

      preserveAt."/persistent" = {
        directories = [
          "/etc/nixos"
          "/var/lib/bluetooth"
          "/etc/ssh"
          {
            directory = "/var/lib/nixos";
            inInitrd = true;
          }
        ];

        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
        ];

        users.adrien = {
          directories = [
            "nixos"
            "podman"
          ];

          files = [
            ".bash_history"
          ];
        };

      };
    };
  };
}

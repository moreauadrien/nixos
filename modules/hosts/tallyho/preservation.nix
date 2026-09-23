# Host tallyho: preservation (impermanence) setup + the `preservation` CLI.
{ self, inputs, ... }: {
  flake.nixosModules.tallyhoPreservation =
    { config, lib, pkgs, ... }:
    let
      # Paths added at runtime with `preservation add` are stored in this
      # JSON file (kept in the config repo) and merged declaratively into
      # the configuration below, so they survive rebuilds.
      extraFile = ./preservation-extra.json;
      extra =
        if builtins.pathExists extraFile
        then builtins.fromJSON (builtins.readFile extraFile)
        else {
          system.directories = [ ];
          system.files = [ ];
          users = { };
        };

      # All preserved paths of the merged configuration; consumed by the
      # CLI script (`preservation ls`).
      pState = config.preservation.preserveAt."/persistent";
      manifest = {
        persistentRoot = "/persistent";
        system = {
          directories = map (d: d.directory) (
            lib.filter (d: d.how != "_intermediate") pState.directories
          );
          files = map (f: f.file) pState.files;
        };
        users = builtins.mapAttrs (_: u: {
          home = u.home;
          directories = map (d: d.directory) (
            lib.filter (d: d.how != "_intermediate") u.directories
          );
          files = map (f: f.file) u.files;
        }) pState.users;
      };

      # The `preservation` CLI script.
      cliScript = pkgs.replaceVars ./preservation.sh {
        jq = "${pkgs.jq}/bin/jq";
        findmnt = "${pkgs.util-linux}/bin/findmnt";
        persist = "/persistent";
        repo = "/home/adrien/nixos";
      };
    in
    {
      # /etc/machine-id is persistent (bind-mounted from /persistent), so
      # systemd-machine-id-commit.service fails on every boot ("not on a
      # temporary file system"). Harmless → mask it.
      systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

      environment.etc."preservation.json".text = builtins.toJSON manifest;

      environment.systemPackages = [
        (pkgs.writeShellScriptBin "preservation" ''
          exec ${pkgs.bash}/bin/bash ${cliScript} "$@"
        '')
      ];

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
          ] ++ (extra.system.directories or [ ]);

          files = [
            {
              file = "/etc/machine-id";
              inInitrd = true;
            }
          ] ++ (extra.system.files or [ ]);

          users =
            let
              base = {
                adrien.directories = [
                  "nixos"
                  "keep"
                  "podman"
                  ".config/hyprmoncfg"
                  ".config/librewolf"
                  ".ssh"
                  ".pi"
                ];
                adrien.files = [ ".bash_history" ];
              };
            in
            lib.foldlAttrs (
              acc: name: u:
                acc // {
                  ${name} = {
                    directories =
                      ((acc.${name} or { }).directories or [ ]) ++ (u.directories or [ ]);
                    files =
                      ((acc.${name} or { }).files or [ ]) ++ (u.files or [ ]);
                  };
                }
            ) base (extra.users or { });
        };
      };
    };
}
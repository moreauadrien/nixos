{
  inputs,
  moduleWithSystem,
  ...
}: {
  perSystem = { pkgs, ... }:
    let
      gondolinNodeModules = pkgs.buildNpmPackage {
        pname = "gondolin-nix-sandbox";
        version = "0.13.0";
        src = ./gondolin-extension;
        npmDepsHash = "sha256-7006UZJ1Oeg+9DeQ3BQ0fMeG7CuX80ZF21NjRFNphyk=";
        dontNpmBuild = true;
        npmRebuildFlags = [ "--ignore-scripts" ];
        installPhase = ''
          mkdir -p $out/node_modules
          cp -a node_modules/. $out/node_modules/
        '';
      };

      gondolin = pkgs.writeShellScriptBin "gondolin" ''
        exec ${pkgs.nodejs_24}/bin/node \
          ${gondolinNodeModules}/node_modules/@earendil-works/gondolin/dist/bin/gondolin.js "$@"
      '';


      # Vendored Gondolin extension: preserve host paths for Git worktrees,
      # and mount clipboard images and read-only agent resources.
      gondolinExtension = pkgs.runCommand "gondolin-extension" { } ''
        # Pi displays the parent directory name for index.ts entry points.
        mkdir -p $out/gondolin-extension
        cp ${./gondolin-extension}/*.ts ${./gondolin-extension}/*.json ${./gondolin-extension}/*.sh $out/gondolin-extension/
        ln -s ${gondolinNodeModules}/node_modules $out/node_modules
      '';
    in
    {
      packages.pi = inputs.wrapper-modules.lib.wrapPackage [
        {
          inherit pkgs;
          package = pkgs.pi-coding-agent;
          runtimePkgs = [
            gondolin
            pkgs.nodejs_24
            pkgs.qemu_kvm
            pkgs.podman
            pkgs.curl
            pkgs.cpio
            pkgs.lz4
            pkgs.e2fsprogs
            pkgs.e2fsprogs.bin
            pkgs.gnutar
            pkgs.which
            pkgs.git
          ];
          # pi dispatches subcommands (install, remove, update, list, config, auth, mcp) on
          # argv[0] and rejects unknown flags, so the -e extension flag must not be injected
          # for those invocations. For regular sessions, prepend it to the real arguments.
          runShell = [
            ''
              set -e
              case "$1" in
                install|remove|uninstall|update|list|config|auth|mcp) ;;
                *) set -- -e "${gondolinExtension}/gondolin-extension/index.ts" "$@" ;;
              esac
            ''
          ];
        }
      ];
    };

  flake.nixosModules.pi = moduleWithSystem ({
    self',
    pkgs,
    ...
  }:
    {
      virtualisation.podman.enable = true;
      users.users.adrien.extraGroups = [ "kvm" ];

      hjem.users.adrien = {
        directory = "/home/adrien";
        packages = [ self'.packages.pi pkgs.podman-compose ];
        files = {
          ".zshrc.d/pi-yolo.zsh".text = ''
            alias pi-yolo='${pkgs.pi-coding-agent}/bin/pi'
          '';
          ".config/containers/containers.conf".text = ''
            [engine]
            image_copy_tmp_dir = "storage"
          '';
          ".config/containers/storage.conf".text = ''
            [storage]
            driver = "overlay"
            graphroot = "/home/adrien/podman/storage"
          '';
        };
      };
    });
}

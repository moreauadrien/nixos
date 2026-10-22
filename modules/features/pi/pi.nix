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
        src = inputs.gondolin-nix-sandbox;
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

      personalResources = pkgs.buildNpmPackage {
        pname = "pi-personal-resources";
        version = "1.0.0";
        src = ./package;
        npmDepsHash = "sha256-JEmwGUcZAeaMTMXR0pDfzctXzV1rRiXEdzo9rqdxbLc=";
        npmFlags = [ "--legacy-peer-deps" ];
        npmRebuildFlags = [ "--ignore-scripts" ];
        dontNpmBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -a package.json extensions skills node_modules $out/
        '';
      };

      # Vendored copy of pi's gondolin example extension with an extra mount
      # for pasted clipboard images (see package/extensions/paste-image.ts).
      gondolinExtension = pkgs.runCommand "gondolin-extension" { } ''
        # Pi displays the parent directory name for index.ts entry points.
        mkdir -p $out/gondolin-extension
        cp ${./gondolin-extension/index.ts} $out/gondolin-extension/index.ts
        ln -s ${gondolinNodeModules}/node_modules $out/node_modules
      '';

      imageTag = "gondolin-nix:${builtins.substring 0 12 (builtins.hashString "sha256" (toString inputs.gondolin-nix-sandbox))}";
    in
    {
      packages.pi = inputs.wrapper-modules.lib.wrapPackage [
        {
          inherit pkgs;
          package = pkgs.pi-coding-agent;
          env = {
            GONDOLIN_DEFAULT_IMAGE = imageTag;
            PI_PERSONAL_RESOURCES = "${personalResources}";
          };
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
          # The repository image uses Podman, so build it at first launch, outside the Nix build sandbox.
          # pi dispatches subcommands (install, remove, update, list, config, auth, mcp) on
          # argv[0] and rejects unknown flags, so the -e extension flag must not be injected
          # for those invocations. For regular sessions, prepend it to the real arguments.
          runShell = [
            ''
              set -e
              if ! ${gondolin}/bin/gondolin image inspect "${imageTag}" >/dev/null 2>&1; then
                ${gondolin}/bin/gondolin build \
                  --config "${inputs.gondolin-nix-sandbox}/build-config.json" \
                  --tag "${imageTag}"
              fi
              case "$1" in
                install|remove|uninstall|update|list|config|auth|mcp) ;;
                *) set -- -e "${gondolinExtension}/gondolin-extension/index.ts" -e "${personalResources}" "$@" ;;
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

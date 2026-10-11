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

      # Vendored copy of pi's gondolin example extension with an extra mount
      # for pasted clipboard images (see config/extensions/paste-image.ts).
      gondolinExtension = pkgs.runCommand "pi-gondolin-extension" { } ''
        mkdir -p $out
        cp ${./gondolin-extension/index.ts} $out/index.ts
        ln -s ${gondolinNodeModules}/node_modules $out/node_modules
      '';

      imageTag = "gondolin-nix:${builtins.substring 0 12 (builtins.hashString "sha256" (toString inputs.gondolin-nix-sandbox))}";
    in
    {
      packages.pi = inputs.wrapper-modules.lib.wrapPackage [
        {
          inherit pkgs;
          package = pkgs.pi-coding-agent;
          addFlag = [ "-e" "${gondolinExtension}/index.ts" ];
          env.GONDOLIN_DEFAULT_IMAGE = imageTag;
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
          runShell = [
            ''
              set -e
              if ! ${gondolin}/bin/gondolin image inspect "${imageTag}" >/dev/null 2>&1; then
                ${gondolin}/bin/gondolin build \
                  --config "${inputs.gondolin-nix-sandbox}/build-config.json" \
                  --tag "${imageTag}"
              fi
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
    let
      inherit (pkgs) lib;
      configFiles = builtins.listToAttrs (
        map (file: {
          name = ".pi/agent/${lib.removePrefix "${toString ./config}/" (toString file)}";
          value.source = file;
        }) (lib.filesystem.listFilesRecursive ./config)
      );
    in
    {
      virtualisation.podman.enable = true;
      users.users.adrien.extraGroups = [ "kvm" ];

      hjem.users.adrien = {
        directory = "/home/adrien";
        packages = [ self'.packages.pi ];
        files = configFiles // {
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

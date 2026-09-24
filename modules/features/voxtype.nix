{
  moduleWithSystem,
  inputs,
  ...
}: {
  flake.nixosModules.voxtype = moduleWithSystem (
    { inputs', pkgs, ... }: {
      imports = [ inputs.voxtype.nixosModules.default ];

      environment.systemPackages = [
        (pkgs.symlinkJoin {
          name = "voxtype-wrapped";
          paths = [ inputs'.voxtype.packages.vulkan ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/voxtype \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.pulseaudio ]}
          '';
        })
      ];
    }
  );
}

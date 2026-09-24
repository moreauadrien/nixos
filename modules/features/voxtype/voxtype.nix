# Voxtype daemon + quickshell frontend QML tree (self-contained feature).
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

            # Ship the quickshell QML tree where `voxtype setup quickshell`
            # expects to find its default source: <binary>/../share/voxtype/quickshell/
            mkdir -p $out/share/voxtype
            cp -r ${./quickshell} $out/share/voxtype/quickshell
          '';
        })
      ];
    }
  );
}

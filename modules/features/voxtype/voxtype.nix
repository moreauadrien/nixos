# Voxtype daemon + quickshell frontend QML tree (self-contained feature).
{
  moduleWithSystem,
  inputs,
  ...
}: {
  flake.nixosModules.voxtype = moduleWithSystem (
    { inputs', pkgs, ... }:
    let
      # `voxtype setup quickshell` locates its default QML source via
      # env::current_exe() (i.e. /proc/self/exe), which resolves the wrapper
      # symlink chain all the way to the real ELF binary in the *unwrapped*
      # package. The tree must therefore ship in that package's share/ dir:
      # <binary>/../share/voxtype/quickshell/
      # voxtype-onnx-unwrapped exposes packages.voxtype-onnx-unwrapped in
      # upstream flake.nix. Its wrapper (upstream wrapOnnx) additionally sets
      # ORT_DYLIB_PATH/LD_LIBRARY_PATH, replicated in the postBuild below.
      voxtype = inputs'.voxtype.packages.voxtype-onnx-unwrapped.overrideAttrs
        (old: {
          postInstall = (old.postInstall or "") + ''
            # Ship the quickshell QML tree where `voxtype setup quickshell`
            # expects its default source: <binary>/../share/voxtype/quickshell/
            mkdir -p $out/share/voxtype
            cp -r ${./quickshell} $out/share/voxtype/quickshell
          '';
        });
    in
    {
      imports = [ inputs.voxtype.nixosModules.default ];

      environment.systemPackages = [
        # Same runtime deps as upstream's wrapVoxtype wrapper, plus
        # pulseaudio for the pactl-based volume control.
        (pkgs.symlinkJoin {
          name = "voxtype-wrapped";
          paths = [ voxtype ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild =
            let
              libExt = if pkgs.stdenv.isDarwin then "dylib" else "so";
              binPath = pkgs.lib.makeBinPath (
                with pkgs;
                [
                  wtype # Wayland typing
                  dotool # Universal typing backend via uinput
                  wl-clipboard # Wayland clipboard (wl-copy)
                  ydotool # Alternative typing backend (X11 and Wayland)
                  xdotool # X11 typing fallback
                  xclip # X11 clipboard fallback
                  libnotify # Desktop notifications
                  pciutils # GPU detection
                  pulseaudio
                ]
              );
            in
            ''
              wrapProgram $out/bin/voxtype \
                --prefix PATH : ${binPath} \
                --set ORT_DYLIB_PATH "${pkgs.onnxruntime}/lib/libonnxruntime.${libExt}" \
                --prefix LD_LIBRARY_PATH : "${pkgs.onnxruntime}/lib"
            '';
        })
      ];
    }
  );
}

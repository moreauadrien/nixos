# Official ElegooSlicer AppImage, wrapped for NixOS.
{ moduleWithSystem, ... }: {
  flake.nixosModules.elegoo-slicer = moduleWithSystem ({ self', ... }: {
    environment.systemPackages = [ self'.packages.elegoo-slicer ];
  });

  perSystem = { pkgs, ... }: {
    packages.elegoo-slicer = let
      pname = "elegoo-slicer";
      version = "1.5.3.5";
      src = pkgs.fetchurl {
        url = "https://github.com/elegooofficial/ElegooSlicer/releases/download/v${version}/ElegooSlicer_Linux_V${version}.AppImage";
        hash = "sha256-ezs/CODQ1Ru0cshYZdG+mwwoOFQj2rocsMOyJdAQGvw=";
      };
      appimageContents = pkgs.appimageTools.extract {
        inherit pname version src;
      };
    in pkgs.appimageTools.wrapType2 {
      inherit pname version src;
      extraInstallCommands = ''
        install -Dm644 ${appimageContents}/*.desktop -t $out/share/applications
        substituteInPlace $out/share/applications/*.desktop \
          --replace-fail 'Exec=AppRun' 'Exec=elegoo-slicer'
        cp -r ${appimageContents}/usr/share/icons $out/share/
      '';
      meta = {
        description = "ELEGOO 3D printing slicer";
        homepage = "https://github.com/elegooofficial/ElegooSlicer";
        license = pkgs.lib.licenses.agpl3Only;
        platforms = [ "x86_64-linux" ];
        mainProgram = pname;
      };
    };
  };
}

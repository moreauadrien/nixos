{
  flake.overlays.default = final: prev: {
    notwaita-cursor = final.stdenv.mkDerivation {
      pname = "notwaita-cursor";
      version = "1.0.0-alpha1";

      src = final.fetchurl {
        url = "https://github.com/ful1e5/notwaita-cursor/releases/download/v1.0.0-alpha1/Notwaita-Black.tar.xz";
        hash = "sha256-P/F4NRBqz/6Ws9//qEKMYdqtfG5LdZa6jihqueZnx88=";
      };

      installPhase = ''
        mkdir -p $out/share/icons
        tar -xf $src -C $out/share/icons
      '';
    };
  };
}

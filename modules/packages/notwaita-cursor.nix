# Notwaita cursor theme as a perSystem package (no global overlay: consumers
# access it via moduleWithSystem + self').
{ ... }: {
  perSystem = { pkgs, ... }: {
    packages.notwaita-cursor = pkgs.stdenv.mkDerivation {
      pname = "notwaita-cursor";
      version = "1.0.0-alpha1";

      src = pkgs.fetchurl {
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

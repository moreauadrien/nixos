{pkgs, ...}: let
  notwaita-cursor = pkgs.stdenv.mkDerivation {
    pname = "notwaita-cursor";
    version = "1.0.0-alpha1";

    src = pkgs.fetchurl {
      url = "https://github.com/ful1e5/notwaita-cursor/releases/download/v1.0.0-alpha1/Notwaita-Black.tar.xz";
      sha256 = "1ky7czkbjsi8isx9cxabdryavnk1ii1aizyznfbgxkva20spiw9z";
    };

    installPhase = ''
      mkdir -p $out/share/icons
      tar -xf $src -C $out/share/icons/
    '';
  };
in {
  home.packages = [notwaita-cursor];

  home.pointerCursor = {
    package = notwaita-cursor;
    name = "Notwaita-Black";
    size = 20;
  };
}

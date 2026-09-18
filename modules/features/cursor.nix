# Notwaita cursor theme: package (perSystem) + activation for the user.
{ moduleWithSystem, ... }: {
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

  flake.nixosModules.cursor = moduleWithSystem ({ self', ... }: {
    hjem.users.adrien = {
      packages = [ self'.packages.notwaita-cursor ];
      files.".icons".source = "${self'.packages.notwaita-cursor}/share/icons";
    };

    environment.sessionVariables = {
      XCURSOR_THEME = "Notwaita-Black";
      XCURSOR_SIZE = "20";
    };
  });
}

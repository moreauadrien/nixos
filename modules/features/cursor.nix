# Notwaita cursor theme: package (perSystem) + activation for the user.
{ moduleWithSystem, ... }: {
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

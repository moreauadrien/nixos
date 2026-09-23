# GTK icon theme: Papirus (same icon set Nautilus had in the legacy branch).
# Legacy used home-manager's gtk.iconTheme, which applies the theme through
# dconf (org/gnome/desktop/interface) — GTK4 apps like Nautilus read GSettings
# first. Reproduced here with the NixOS dconf profile defaults.
{ ... }: {
  flake.nixosModules.gtk-theme = { pkgs, ... }: {
    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings."org/gnome/desktop/interface" = {
            icon-theme = "Papirus";
            # Legacy also set the default terminal via dconf.
            cursor-theme = "Notwaita-Black";
          };
        }
      ];
    };

    hjem.users.adrien = {
      packages = [ pkgs.papirus-icon-theme ];
    };
  };
}

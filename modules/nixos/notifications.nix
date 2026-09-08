{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    mako
    # loader gdk-pixbuf pour le SVG -> mako accepte les icônes .svg directement
    librsvg
  ];
}

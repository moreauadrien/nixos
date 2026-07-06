{
  config,
  pkgs,
  ...
}: {
  xdg.configFile."waybar" = {
    source = ../../dotfiles/waybar;
    recursive = true;
  };
}

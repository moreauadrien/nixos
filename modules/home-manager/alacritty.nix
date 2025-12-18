{
  config,
  pkgs,
  ...
}: {
  xdg.configFile."alacritty" = {
    source = ../../dotfiles/alacritty;
    recursive = true;
  };
}

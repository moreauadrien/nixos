{
  config,
  pkgs,
  ...
}: {
  xdg.configFile."mako" = {
    source = ../../../dotfiles/mako;
    recursive = true;
  };
}

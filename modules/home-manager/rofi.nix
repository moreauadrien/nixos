{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    rofi
  ];

  xdg.configFile."rofi" = {
    source = ../../dotfiles/rofi;
    recursive = true;
  };

  home.file.".local/share/fonts" = {
    source = ../../dotfiles/rofi/fonts;
    recursive = true;
  };
}

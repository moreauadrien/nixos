{
  config,
  pkgs,
  ...
}: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    plugins = with pkgs; [
      rofi-calc
    ];
  };

  xdg.configFile."rofi" = {
    source = ../../dotfiles/rofi;
    recursive = true;
  };

  home.file.".local/share/fonts" = {
    source = ../../dotfiles/rofi/fonts;
    recursive = true;
  };
}

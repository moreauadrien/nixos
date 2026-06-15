{
  config,
  pkgs,
  ...
}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;
  };

  home.packages = with pkgs; [
    git
    gnumake
    unzip
    gcc
    ripgrep
    fd
    xclip
  ];

  xdg.configFile."nvim" = {
    source = ../../../dotfiles/nvim;
    recursive = true;
  };
}

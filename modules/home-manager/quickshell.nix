{ pkgs, ... }: {
  home.packages = with pkgs; [
    quickshell
    kdePackages.qtdeclarative
  ];

  xdg.configFile."quickshell" = {
    source = ../../dotfiles/quickshell;
    recursive = true;
  };
}

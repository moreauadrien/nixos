{...}: {
  home.file.".local/bin" = {
    source = ../../dotfiles/bin;
    recursive = true;
  };
}

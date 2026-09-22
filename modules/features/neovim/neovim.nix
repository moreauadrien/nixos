# Neovim editor: binary, companion tools and the config from ./config.
{ pkgs, ... }: {
  flake.nixosModules.neovim = { pkgs, ... }: {

    programs.neovim = {
      enable = true;
      vimAlias = true;
      defaultEditor = true;
    };

    hjem.users.adrien.files.".config/nvim".source = ./config;
  };
}

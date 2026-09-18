# Neovim editor: binary, companion tools and the config from ./config.
{ pkgs, ... }: {
  flake.nixosModules.neovim = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      neovim
      # Companion tools used by the config (telescope, treesitter, LSP).
      gnumake
      gcc
      unzip
      ripgrep
      fd
      xclip
      # qmlls (Mason's build is a generic binary, doesn't run on NixOS).
      kdePackages.qtdeclarative
    ];

    hjem.users.adrien.files.".config/nvim".source = ./config;
  };
}

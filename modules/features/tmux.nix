# Tmux terminal multiplexer: binary + config from dotfiles/tmux.conf.
{ self, ... }: {
  flake.nixosModules.tmux = { pkgs, ... }: {
    programs.tmux.enable = true;

    hjem.users.adrien.files.".tmux.conf".source = "${self}/dotfiles/tmux.conf";
  };
}

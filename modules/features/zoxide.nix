{
  flake.nixosModules.zoxide = { pkgs, ... }: {
    hjem.users.adrien = {
      packages = [ pkgs.zoxide ];
      files.".zshrc.d/zoxide.zsh".text = ''
        eval "$(${pkgs.zoxide}/bin/zoxide init --cmd cd zsh)"
      '';
    };
  };
}

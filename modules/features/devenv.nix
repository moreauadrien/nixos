{
  flake.nixosModules.devenv = { pkgs, ... }: {

    environment.systemPackages = with pkgs; [
      devenv
    ];

    hjem.users.adrien.files.".zshrc.d/devenv.zsh".text = ''
      eval "$(devenv hook zsh)"
    '';
  };
}

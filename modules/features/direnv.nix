{
    flake.nixosModules.direnv = { pkgs, ... } : {
        environment.systemPackages = with pkgs; [
            direnv
        ];

        hjem.users.adrien.files.".zshrc.d/devenv.zsh".text = ''
            eval "$(direnv hook zsh)"
        '';
    };
}

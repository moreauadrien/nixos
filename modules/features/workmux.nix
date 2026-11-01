{ inputs, ... }: {
  flake.nixosModules.workmux = { pkgs, ... }: {
    environment.systemPackages = [ inputs.workmux.packages.${pkgs.stdenv.hostPlatform.system}.default ];

    hjem.users.adrien.files.".zshrc.d/workmux.zsh".text = ''
      alias wm='workmux'
    '';
  };
}

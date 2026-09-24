# Nix daemon settings.
{ ... }: {
  flake.nixosModules.nix = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "adrien" ];
    };

    nixpkgs.config.allowUnfree = true; 
  };
}

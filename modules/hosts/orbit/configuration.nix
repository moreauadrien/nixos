{ ... }: {
  flake.nixosModules.orbitConfiguration = { pkgs, ... }: {
    networking.hostName = "orbit";

    wsl.enable = true;
    wsl.defaultUser = "nixos";

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      neovim
      tmux
      git
      cursor-cli
      wget
    ];

    programs.nix-ld.enable = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    system.stateVersion = "26.05";
  };
}

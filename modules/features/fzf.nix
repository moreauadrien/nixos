{
  flake.nixosModules.fzf = { pkgs, ... }: {
    hjem.users.adrien = {
      packages = [ pkgs.fzf ];
    };

    programs.fzf = {
      fuzzyCompletion = true;
      keybindings = true;
    };
  };
}

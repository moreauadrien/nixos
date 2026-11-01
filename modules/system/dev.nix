# Development profile: composes the dev tools (like voidarc's profiles).
{ self, ... }: {
  flake.nixosModules.dev = { pkgs, ... }: {
    imports = with self.nixosModules; [
      neovim
      intellij-idea
      tmux
      workmux
      pi
      pifzf
      shell
      zoxide
      sesh
      devenv
      direnv
    ];

    environment.systemPackages = [ pkgs.fd pkgs.ripgrep];
  };
}

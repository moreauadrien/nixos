# Development profile: composes the dev tools (like voidarc's profiles).
{ self, ... }: {
  flake.nixosModules.dev = { pkgs, ... }: {
    imports = with self.nixosModules; [
      neovim
      tmux
      pi
    ];

    environment.systemPackages = [ pkgs.devenv ];
  };
}

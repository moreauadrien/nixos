# Set of supported systems (kept in a module, like voidarc's parts.nix,
# so flake.nix stays minimal).
{ inputs, ... }: {
  systems = [ "x86_64-linux" ];

  # Mirror of `nixpkgs.config.allowUnfree = true` (core/nix.nix) for the
  # perSystem pkgs: `moduleWithSystem` and wrapper-modules inject these pkgs
  # into nixos modules, so unfree packages (e.g. spotify) must be allowed
  # here too. Note: passing `config` explicitly shadows
  # ~/.config/nixpkgs/config.nix (empty by default).
  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  };
}

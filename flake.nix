{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprdynamicmonitors.url = "github:fiffeek/hyprdynamicmonitors";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elephant.url = "github:abenz1267/elephant";

    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      hyprdynamicmonitors,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (final: prev: {
            brave-origin = prev.callPackage ./pkgs/brave-origin.nix { };
            greywall = final.callPackage ./pkgs/greywall.nix { };
            greyproxy = final.callPackage ./pkgs/greyproxy.nix { };
          })
        ];
      };
    in
    {
      packages.${system} = {
        inherit (pkgs) greywall greyproxy brave-origin;
      };

      nixosConfigurations.tallyho = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          pkgs-unstable = import nixpkgs-unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
        modules = [
          hyprdynamicmonitors.nixosModules.default
          ./hosts/tallyho/configuration.nix
          ./modules/nixos
          (
            {
              config,
              pkgs,
              ...
            }:
            {
              nixpkgs.overlays = [
                (final: prev: {
                  brave-origin = prev.callPackage ./pkgs/brave-origin.nix { };
                  greywall = final.callPackage ./pkgs/greywall.nix { };
                  greyproxy = final.callPackage ./pkgs/greyproxy.nix { };
                })
              ];
            }
          )
        ];
      };

      homeManagerModules.default = ./modules/home-manager;
    };
}

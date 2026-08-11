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

    diceware-fr.url = "github:moreauadrien/diceware-fr";

    smolvm.url = "github:smol-machines/smolvm";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      hyprdynamicmonitors,
      ...
    }@inputs:
    {
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
          {
            nixpkgs.overlays = [ inputs.smolvm.overlays.default ];
          }
          ./hosts/tallyho/configuration.nix
          ./modules/nixos
        ];
      };

      homeManagerModules.default = ./modules/home-manager;
    };
}

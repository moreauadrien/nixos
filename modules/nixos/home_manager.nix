{inputs, ...}: {
  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {inherit inputs;};
    users = {
      "adrien" = {
        imports = [
          ../../hosts/tallyho/home.nix
          inputs.self.outputs.homeManagerModules.default
        ];
      };
    };
  };
}

{
  inputs,
  pkgs-unstable,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs;
      inherit pkgs-unstable;
    };
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

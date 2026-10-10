{
    flake.nixosModules.pi = { pkgs, ... } : {
        hjem.users.adrien = {
          directory = "/home/adrien";
          packages = [ pkgs.pi-coding-agent ];
        };
    };
}

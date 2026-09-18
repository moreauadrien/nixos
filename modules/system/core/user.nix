# Base user: adrien with hjem, sudo and shell packages.
{ moduleWithSystem, ... }: {
  flake.nixosModules.user = moduleWithSystem ({
    self',
    pkgs,
    ...
  }: {
    hjem.clobberByDefault = true;

    users.users.adrien = {
      isNormalUser = true;
      initialPassword = "adrien";
      extraGroups = [ "wheel" ];
      packages = [ pkgs.tree ];
    };

    hjem.users.adrien = {
      directory = "/home/adrien";
      packages = [ self'.packages.git ];
    };

    security.sudo.extraRules = [
      {
        users = [ "adrien" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    environment.systemPackages = [
      pkgs.neovim
    ];
  });
}

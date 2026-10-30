# Hyprsunset night light.
{
  flake.nixosModules.hyprsunset = { pkgs, ... } : {
    hjem.users.adrien.files.".config/hypr/hyprsunset.conf".text = ''
      profile {
          time = 08:00
          identity = true
      }

      profile {
          time = 22:00
          temperature = 4500
      }
    '';

    environment.systemPackages = [ pkgs.hyprsunset ];
  };
}

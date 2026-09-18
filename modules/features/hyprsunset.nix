# Hyprsunset night light.
{ pkgs, ... }: {
  flake.nixosModules.hyprsunset = {
    hjem.users.adrien.files.".config/hypr/hyprsunset.conf".text = ''
      max-gamma = 150

      profile {
          time = 7:30
          identity = true
      }

      profile {
          time = 21:00
          temperature = 5500
          gamma = 0.8
      }
    '';

    environment.systemPackages = [ pkgs.hyprsunset ];
  };
}

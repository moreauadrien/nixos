{
  flake.nixosModules.printing = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.simple-scan ];

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    services.printing = {
      enable = true;
      drivers = [ pkgs.hplipWithPlugin ];
    };

    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.hplipWithPlugin ];
    };
  };
}

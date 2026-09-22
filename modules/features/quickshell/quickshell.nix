# Quickshell bar: binary + its config (self-contained feature).
{ ... }: {
  flake.nixosModules.quickshell = { pkgs, ... }: {
    # D-Bus service consumed by the PowerWidget (battery indicator).
    services.upower.enable = true;

    environment.systemPackages = [ pkgs.quickshell ];

    hjem.users.adrien.files.".config/quickshell".source = ./config;
  };
}

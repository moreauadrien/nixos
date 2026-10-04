# Quickshell bar: binary + its config (self-contained feature).
{ ... }: {
  flake.nixosModules.quickshell = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.quickshell pkgs.libnotify ];

    hjem.users.adrien.files.".config/quickshell".source = ./config;
  };
}

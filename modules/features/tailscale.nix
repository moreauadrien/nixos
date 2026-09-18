# Tailscale mesh VPN plus its tray GUI.
{ ... }: {
  flake.nixosModules.tailscale = { pkgs, ... }: {
    services.tailscale.enable = true;

    environment.systemPackages = with pkgs; [
      trayscale
    ];
  };
}

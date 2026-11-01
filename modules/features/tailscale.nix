# Tailscale mesh VPN, controlled by the Quickshell widget.
{ ... }: {
  flake.nixosModules.tailscale = { ... }: {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      # Let the desktop user control Tailscale through its local API, without sudo.
      extraSetFlags = [ "--operator=adrien" ];
    };
  };
}

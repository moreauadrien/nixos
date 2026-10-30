# Tailscale mesh VPN, controlled by the Quickshell widget or tray GUI.
{ ... }: {
  flake.nixosModules.tailscale = { pkgs, ... }: {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      # Let the desktop user control Tailscale through its local API, without sudo.
      extraSetFlags = [ "--operator=adrien" ];
    };

    environment.systemPackages = with pkgs; [
      trayscale
    ];
  };
}

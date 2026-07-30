{pkgs, ...}: {
  imports = [
    ./plymouth.nix
    ./desktop_environment.nix
    ./wireless_networking.nix
    ./bluetooth.nix
    ./sound.nix
    ./printing.nix
    ./virtualisation.nix
    ./power-management.nix
    ./firewall.nix
    ./home_manager.nix
    ./update.nix
    ./garbage_collector.nix
    ./notifications.nix
    ./webcam.nix
    ./hardware-acceleration.nix
    ./steam.nix
  ];
}

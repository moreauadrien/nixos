{pkgs, ...}: {
  imports = [
    ./plymouth.nix
    ./desktop_environment.nix
    ./wireless_networking.nix
    ./bluetooth.nix
    ./sound.nix
    ./printing.nix
    ./virtualisation.nix
    ./tlp.nix
    ./firewall.nix
    ./home_manager.nix
    ./update.nix
    ./garbage_collector.nix
    ./notifications.nix
  ];
}

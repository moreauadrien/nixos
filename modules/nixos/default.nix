{pkgs, ...}: {
  imports = [
    ../../modules/nixos/plymouth.nix
    ../../modules/nixos/desktop_environment.nix
    ../../modules/nixos/wireless_networking.nix
    ../../modules/nixos/bluetooth.nix
    ../../modules/nixos/sound.nix
    ../../modules/nixos/printing.nix
    ../../modules/nixos/virtualisation.nix
    ../../modules/nixos/tlp.nix
    ../../modules/nixos/firewall.nix
  ];
}

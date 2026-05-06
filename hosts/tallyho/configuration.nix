# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  ...
}: let
  system = "x86_64-linux";
  unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
in {
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Early KMS pour écran externe USB-C
  boot.initrd.kernelModules = ["i915"];

  boot.initrd.luks.devices = {
    root = {
      device = "/dev/nvme0n1p2";
      preLVM = true;
    };
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  networking.hostName = "tallyho";

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  console.keyMap = "fr";

  # Configure keymap for loggin screen
  services.xserver.xkb = {
    layout = "fr";
    variant = "azerty";
  };

  users.users.adrien = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Adrien";
    extraGroups = ["wheel" "libvirt" "libvirtd" "dialout"];
    packages = with pkgs; [
      btop
      fastfetch
      spotify
    ];
  };

  nixpkgs.config.allowUnfree = true;

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    gnutar
    curl
    brightnessctl
    jq

    cyberchef
    file-roller
    evince


    onlyoffice-desktopeditors

    typst
  ];

  services.udisks2.enable = true;

  programs.tmux.enable = true;

  services.tailscale.enable = true;

  services.gvfs.enable = true;

  system.stateVersion = "25.11"; # Do not edit
}

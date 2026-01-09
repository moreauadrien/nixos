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
  boot.initrd.luks.devices = {
    root = {
      device = "/dev/nvme0n1p2";
      preLVM = true;
    };
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  networking.hostName = "tallyho";

  # Automatic updating
  system.autoUpgrade.enable = true;
  system.autoUpgrade.dates = "weekly";

  # Automatic cleanup
  nix.gc.automatic = true;
  nix.gc.dates = "daily";
  nix.gc.options = "--delete-older-than 10d";
  nix.settings.auto-optimise-store = true;

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
    extraGroups = ["wheel" "libvirt" "libvirtd"];
    packages = with pkgs; [
      btop
      fastfetch
      spotify
    ];
  };

  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  programs.localsend.enable = true;

  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    users = {
      "adrien" = import ./home.nix;
    };
  };

  environment.systemPackages = with pkgs; [
    gnutar
    curl
    brightnessctl
    jq

    discord

    go
    cyberchef
    file-roller
    evince

    onlyoffice-desktopeditors
    bun
    nodejs_24

    sqlc
    air

    typst
  ];

  services.udisks2.enable = true;

  programs.tmux.enable = true;

  services.tailscale.enable = true;


  services.gvfs.enable = true;

  system.stateVersion = "25.11"; # Do not edit
}

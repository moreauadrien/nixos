# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/desktop-environment.nix
    ../../modules/nixos/wireless.nix
    ../../modules/nixos/bluetooth.nix
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
    extraGroups = ["networkmanager" "wheel"];
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
  ];

  programs.tmux.enable = true;
  programs.firefox.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "25.11"; # Do not edit
}

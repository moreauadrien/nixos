{ self, inputs, ... }: {

  flake.nixosModules.tallyhoConfiguration =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    {
      imports = [
        self.nixosModules.tallyhoHardware
        self.nixosModules.desktop
      ];

      # Use the GRUB 2 boot loader.
      boot.loader.grub.enable = true;
      # boot.loader.grub.efiSupport = true;
      # boot.loader.grub.efiInstallAsRemovable = true;
      # boot.loader.efi.efiSysMountPoint = "/boot/efi";
      # Define on which hard drive you want to install Grub.
      # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      networking.hostName = "tallyho";
      networking.networkmanager.enable = true;

      time.timeZone = "Europe/Paris";

      i18n = {
        defaultLocale = "en_US.UTF-8";
        extraLocaleSettings = {
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
      };

      console.keyMap = "fr";

      # Enable sound.
      # services.pulseaudio.enable = true;
      # OR
      # services.pipewire = {
      #   enable = true;
      #   pulse.enable = true;
      # };

      # Enable touchpad support (enabled default in most desktopManager).
      # services.libinput.enable = true;

      users.users.adrien = {
        isNormalUser = true;
        initialPassword = "adrien";
        extraGroups = [ "wheel" ];
        packages = with pkgs; [
          tree
        ];
      };

      hjem = {
        clobberByDefault = true;
        users.adrien = {
          directory = "/home/adrien";
        };
      };

      # Only for testing
      users.users.adrien.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDaoAxpR4xoz28qWydEXLeuBI1FlakwnYJyNnHjW62wG adrienmoreau@ik.me"
      ];

      nix.settings.trusted-users = [ "adrien" ];

      security.sudo.extraRules = [
        {
          users = [ "adrien" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      environment.systemPackages = with pkgs; [
        neovim
      ];

      services.openssh.enable = true;

      system.stateVersion = "26.05";
    };
}

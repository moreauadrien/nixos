{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/home-manager/hyprland.nix
    ../../modules/home-manager/neovim.nix
    ../../modules/home-manager/alacritty.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/scripts.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "adrien";
  home.homeDirectory = "/home/adrien";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    alejandra
    libnotify
    nerd-fonts.jetbrains-mono
    signal-desktop
    zsh
    fzf
  ];

  programs.fzf.enableZshIntegration = true;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.file.".tmux.conf".source = ../../dotfiles/tmux.conf;

  xdg.configFile."nvim" = {
    source = ../../dotfiles/nvim;
    recursive = true;
  };

  xdg.configFile."hypr" = {
    source = ../../dotfiles/hypr;
    recursive = true;
  };

  xdg.configFile."waybar" = {
    source = ../../dotfiles/waybar;
    recursive = true;
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/adrien/etc/profile.d/hm-session-vars.sh
  #

  services.udiskie = {
    enable = true;
    settings = {
      program_options = {
        file_manager = "${pkgs.nautilus}/bin/nautilus";
      };
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      bindkey -s ^f "tmux-sessionizer\n"
    '';

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
    };

    shellAliases = {
      vim = "nvim";
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

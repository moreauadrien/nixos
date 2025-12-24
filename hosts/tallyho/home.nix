{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/home-manager/hyprland.nix
    ../../modules/home-manager/waybar.nix
    ../../modules/home-manager/rofi.nix
    ../../modules/home-manager/neovim.nix
    ../../modules/home-manager/alacritty.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/scripts.nix
  ];

  home.username = "adrien";
  home.homeDirectory = "/home/adrien";

  home.stateVersion = "25.11"; # Do not edit

  home.packages = with pkgs; [
    alejandra
    libnotify
    nerd-fonts.jetbrains-mono
    signal-desktop
    zsh
  ];

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home.file.".tmux.conf".source = ../../dotfiles/tmux.conf;

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

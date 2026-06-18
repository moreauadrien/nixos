{
  #inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  home.username = "adrien";
  home.homeDirectory = "/home/adrien";

  home.stateVersion = "25.11"; # Do not edit

  home.packages = with pkgs; [
    alejandra
    libnotify
    nerd-fonts.jetbrains-mono
    signal-desktop
    zsh
    devenv
    asciinema
  ];

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.ssh = {
    enable = true;
    settings = {
      "bicycle" = {
        header = "Host 192.168.1.4";
        user = "deploy";
        identityFile = "~/.ssh/colmena";
      };
    };
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
    autosuggestion.enable = false;
    syntaxHighlighting.enable = true;

    initContent = ''
      eval "$(devenv hook zsh)"

      bindkey -s ^f "tmux-sessionizer\n"
    '';

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  #programs.walker.enable = true;
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

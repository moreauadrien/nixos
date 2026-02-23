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
    autosuggestion.enable = false;
    syntaxHighlighting.enable = true;

    initContent = ''
      bindkey -s ^f "tmux-sessionizer\n"

      if [[ -n "$NIX_SHELL_NAME" ]]; then
        PROMPT="%F{cyan}[$NIX_SHELL_NAME]%f $PROMPT"
      fi

      function _auto_nix_develop() {
        if [[ -f flake.nix ]] && [[ -z "$IN_NIX_SHELL" ]]; then
          nix develop
        fi
      }

      chpwd() { _auto_nix_develop }

      _auto_nix_develop
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

  #programs.walker.enable = true;
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

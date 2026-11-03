{ moduleWithSystem, lib, ... }: {
  flake.nixosModules.sesh = moduleWithSystem ({ self', pkgs, ... }: {
    environment.systemPackages = [ pkgs.sesh self'.packages.sesh-picker ];

    hjem.users.adrien.files.".config/sesh/sesh.toml".source =
      (pkgs.formats.toml {}).generate "sesh.toml" {
        session = [{
          name = "nixos";
          path = "~/nixos";
          startup_command = lib.concatStringsSep " && " [
            "${pkgs.tmux}/bin/tmux rename-window -t 'nixos:' work"
            "${pkgs.tmux}/bin/tmux split-window -d -h -t 'nixos:work.1' -c ~/nixos -p 50"
            "${pkgs.tmux}/bin/tmux split-window -d -v -t 'nixos:work.2' -c ~/nixos"
            "${pkgs.tmux}/bin/tmux send-keys -t 'nixos:work.2' '${self'.packages.touffu}/bin/touffu' C-m"
            "${self'.packages.pi}/bin/pi"
          ];
        }];
      };

    hjem.users.adrien.files.".zshrc.d/sesh.zsh".text = ''
      bindkey -s ^f "${self'.packages.sesh-picker}/bin/sesh-picker\n"
    '';
  });

  perSystem = { pkgs, ... }: {
    packages.sesh-picker = pkgs.writeShellApplication {
      name = "sesh-picker";
      runtimeInputs = with pkgs; [ sesh fzf fd tmux zoxide ];
      text = ''
        picker=(fzf)
        if [[ -n ''${TMUX:-} ]]; then
          picker=(fzf-tmux -p '55%,60%')
        fi

        selected=$(sesh list -i | "''${picker[@]}" \
          --ansi --no-sort --border-label ' sesh ' --prompt '⚡  ' \
          --header '  ^a all ^t tmux ^x zoxide ^g config ^d tmux kill ^f find' \
          --bind 'tab:down,btab:up' \
          --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list -i)' \
          --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -it)' \
          --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -ic)' \
          --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -iz)' \
          --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
          --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)' \
        ) || exit 0

        [[ -n $selected ]] || exit 0
        sesh connect "$selected"
      '';
    };
  };
}

# Tmux terminal multiplexer: binary + config (inlined, single file).
{ moduleWithSystem, ... }: {
  flake.nixosModules.tmux = moduleWithSystem ({ self', pkgs, ... }: {
    programs.tmux.enable = true;

    hjem.users.adrien.files.".tmux.conf".text = ''
      set -g default-terminal "tmux-256color"
      set -g status-style 'bg=#333333 fg=#5eacd3'
      set -g extended-keys on
      set -g extended-keys-format csi-u

      set -g base-index 1
      set -g pane-base-index 1
      set -g mouse on
      set-option -g renumber-windows on
      set-window-option -g mode-keys vi

      bind a new-pane -x 80% -y 60% -X 10% -Y 20% '${self'.packages.pifzf}/bin/pifzf || { printf "\nPress Enter to close..."; read -r _; }'
      bind f new-pane -x 80% -y 60% -X 10% -Y 20% '${self'.packages.ts}/bin/ts'

      bind-key "J" run-shell "${pkgs.sesh}/bin/sesh connect \"$( \
        ${pkgs.sesh}/bin/sesh list -i | ${pkgs.fzf}/bin/fzf-tmux -p 55%,60% \
          --ansi --no-sort --border-label ' sesh ' --prompt '⚡  ' \
          --header '  ^a all ^t tmux ^x zoxide ^g config ^d tmux kill ^f find' \
          --bind 'tab:down,btab:up' \
          --bind 'ctrl-a:change-prompt(⚡  )+reload(${pkgs.sesh}/bin/sesh list -i)' \
          --bind 'ctrl-t:change-prompt(🪟  )+reload(${pkgs.sesh}/bin/sesh list -it)' \
          --bind 'ctrl-g:change-prompt(⚙️  )+reload(${pkgs.sesh}/bin/sesh list -ic)' \
          --bind 'ctrl-x:change-prompt(📁  )+reload(${pkgs.sesh}/bin/sesh list -iz)' \
          --bind 'ctrl-f:change-prompt(🔎  )+reload(${pkgs.fd}/bin/fd -H -d 2 -t d -E .Trash . ~)' \
          --bind 'ctrl-d:execute(${pkgs.tmux}/bin/tmux kill-session -t {})+change-prompt(⚡  )+reload(${pkgs.sesh}/bin/sesh list)' \
      )\""

      bind -r ^ last-window
      bind -r k select-pane -U
      bind -r j select-pane -D
      bind -r h select-pane -L
      bind -r l select-pane -R
    '';
  });
}

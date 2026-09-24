# `config` CLI: gum-powered menu to rebuild the system and manage the
# repo's feature worktrees (test / merge / delete / explore).
{ moduleWithSystem, ... }: {
  perSystem = { pkgs, ... }: {
    packages.config = pkgs.writeShellScriptBin "config" ''
      set -uo pipefail

      GUM="${pkgs.gum}/bin/gum"
      GIT="${pkgs.git}/bin/git"
      AWK="${pkgs.gawk}/bin/awk"
      # The repo lives on the host at /home/adrien/nixos (bare), with the
      # main checkout in main/ and one worktree per feature branch.
      REPO=/home/adrien/nixos
      MAIN=$REPO/main
      HOST=tallyho

      banner() {
        clear
        $GUM style --border double --border-foreground 212 --align center \
          --foreground 212 --bold ' CONFIG ' \
          'nixos rebuilds & worktree manager'
      }

      msg() { $GUM style --foreground 46 "$1"; }
      err() { $GUM style --foreground 196 "$1"; }

      pause() { read -rp $'\nPress enter to continue...' _; }

      # Fill FEATURES (branch names) and WPATHS (matching worktree paths)
      # from `git worktree list`, excluding the bare repo and main.
      list_features() {
        local out br wt
        out=$($GIT -C "$REPO" worktree list --porcelain | $AWK '
          /^worktree / { wt = $2 }
          /^bare/      { wt = "" }
          /^branch /   {
            br = $2; sub("refs/heads/", "", br)
            n = split(wt, p, "/")
            if (wt != "" && p[n] != "main") print br "\t" wt
          }')
        FEATURES=()
        WPATHS=()
        while IFS=$'\t' read -r br wt; do
          [ -n "$br" ] || continue
          FEATURES+=("$br")
          WPATHS+=("$wt")
        done <<< "$out"
      }

      while true; do
        banner
        action=$($GUM choose --header ' What do you want to do? ' \
          'switch' 'features' 'quit') || exit 0

        case $action in
          switch)
            sudo nixos-rebuild switch --flake "$MAIN#$HOST" \
              && msg 'Switch done.' || err 'Switch failed.'
            pause
            ;;

          features)
            list_features
            if [ ''${#FEATURES[@]} -eq 0 ]; then
              msg 'No unmerged feature worktrees.'
              pause
              continue
            fi

            branch=$($GUM choose --header ' Feature branches ' \
              "''${FEATURES[@]}") || continue
            wt=""
            for i in "''${!FEATURES[@]}"; do
              [ "''${FEATURES[$i]}" = "$branch" ] && wt=''${WPATHS[$i]}
            done

            act=$($GUM choose --header " $branch ($wt) " \
              'test' 'merge' 'delete' 'explore' 'back') || continue

            case $act in
              test)
                # Build + activate the test generation from the feature worktree.
                sudo nixos-rebuild test --flake "$wt#$HOST" \
                  && msg 'Test done.' || err 'Test failed.'
                pause
                ;;
              merge)
                $GUM confirm "Merge '$branch' into main, then remove its worktree and branch?" || continue
                if $GIT -C "$MAIN" merge "$branch"; then
                  $GIT -C "$REPO" worktree remove "$wt"
                  $GIT -C "$REPO" branch -d "$branch"
                  msg "Merged '$branch', worktree and branch removed."
                  if $GUM confirm 'Rebuild the system now (nixos-rebuild switch)?'; then
                    sudo nixos-rebuild switch --flake "$MAIN#$HOST" \
                      && msg 'Switch done.' || err 'Switch failed.'
                  fi
                else
                  # Merge conflict: leave everything in place so the user
                  # can resolve it in the main checkout.
                  err "Merge failed: resolve the conflict in $MAIN."
                fi
                pause
                ;;
              delete)
                $GUM confirm --affirmative 'Delete' --negative 'Keep' \
                  "Remove worktree and branch '$branch'?" || continue
                $GIT -C "$REPO" worktree remove --force "$wt"
                $GIT -C "$REPO" branch -D "$branch"
                msg "Deleted worktree and branch '$branch'."
                pause
                ;;
              explore)
                # Open neovim in the worktree (nvim from the user's PATH so
                # the hjem-managed config is used).
                (cd "$wt" && exec nvim)
                ;;
            esac
            ;;

          quit)
            exit 0
            ;;
        esac
      done
    '';
  };

  flake.nixosModules.config-cli = moduleWithSystem ({ self', ... }: {
    hjem.users.adrien.packages = [ self'.packages.config ];
  });
}

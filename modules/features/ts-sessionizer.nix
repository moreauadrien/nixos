# ts: tmux sessionizer CLI — pick a directory with fzf (or pass one as an
# argument), then create / attach / switch to its tmux session. Session names
# are derived deterministically from the path, never from tmux state.
{
  moduleWithSystem,
  lib,
  ...
}: let
  # Directories to scan for sessions (tilde expands to $HOME at runtime).
  roots = [ "~" ];

  # Search depth below each root.
  maxDepth = 3;

  # Bash array literal of the quoted roots, interpolated into the script.
  bashRoots = lib.concatStringsSep " " (map lib.escapeShellArg roots);
in {
  flake.nixosModules.ts-sessionizer = moduleWithSystem ({ self', ... }: {
    hjem.users.adrien.packages = [ self'.packages.ts ];

    # zsh snippet: <C-f> runs ts from the shell (sourced by the shell module's
    # .zshrc via ~/.zshrc.d/*.zsh).
    hjem.users.adrien.files.".zshrc.d/ts-sessionizer.zsh".text = ''
      bindkey -s ^f "ts\n"
    '';
  });

  perSystem = { pkgs, ... }: {
    packages.ts = pkgs.writeShellApplication {
      name = "ts";
      runtimeInputs = with pkgs; [
        tmux
        fzf
        findutils
        coreutils
      ];
      text = ''
        roots=( ${bashRoots} )
        max_depth=${toString maxDepth}

        # Directories whose whole subtree is never proposed.
        exclude_names=(node_modules .venv venv target dist build result Trash)

        # Expand ~ in the roots to $HOME.
        expanded_roots=()
        for root in "''${roots[@]}"; do
          expanded_roots+=("''${root/#\~/$HOME}")
        done

        # Scan the roots: regular directories, excluding hidden dirs and the
        # excluded names (with their subtree).
        excl_args=()
        for name in "''${exclude_names[@]}"; do
          excl_args+=(-o -name "$name")
        done

        declare -A existing_names
        while IFS= read -r s; do
          [[ -n $s ]] && existing_names["$s"]=1
        done < <(tmux list-sessions -F '#S' 2>/dev/null || true)

        selected=""
        declare -a dirs=()
        if [[ $# -eq 1 ]]; then
          selected=$(realpath -- "$1") || {
            echo "ts: not a directory: $1" >&2
            exit 1
          }
          if [[ ! -d $selected ]]; then
            echo "ts: not a directory: $1" >&2
            exit 1
          fi
        elif [[ $# -gt 1 ]]; then
          echo "usage: ts [directory]" >&2
          exit 2
        fi

        # Always scan the roots so the naming set is identical in both modes;
        # the argument-selected directory is merged into it below.
        while IFS= read -r dir; do
          dirs+=("$dir")
        done < <(
          for root in "''${expanded_roots[@]}"; do
            find "$root" -mindepth 1 -maxdepth "$max_depth" \
              \( -name '.*' "''${excl_args[@]}" \) -prune \
              -o -type d -print 2>/dev/null
          done | sort -u
        )
        # Make sure the argument-selected directory is part of the scanned set
        # so naming is stable (no-op in picker mode: selected is still empty).
        if [[ -n $selected ]]; then
          found=1
          for dir in "''${dirs[@]}"; do
            [[ $dir == "$selected" ]] && found=0 && break
          done
          [[ $found -eq 0 ]] || dirs+=("$selected")
          mapfile -t dirs < <(printf '%s\n' "''${dirs[@]}" | sort -u)
        fi
        if [[ $# -eq 0 && ''${#dirs[@]} -eq 0 ]]; then
          echo "ts: no directories found" >&2
          exit 0
        fi

        # Session names: the basename if unique across the scanned set,
        # otherwise enough parent components to disambiguate (dev/api and
        # app/api -> dev-api and app-api). Assignment order is the sorted dir
        # list, so the result is stable and independent of tmux state.
        declare -A base_count taken_names dir_name
        for dir in "''${dirs[@]}"; do
          IFS='/' read -ra c <<< "$dir"
          base="''${c[''${#c[@]}-1]}"
          base_count["$base"]=$(( ''${base_count["$base"]:-0} + 1 ))
        done
        # Assigns the computed name to the global `sname` (no command
        # substitution: it would run in a subshell and lose taken_names).
        session_name() {
          local dir=$1 IFS='/'
          local -a comps=()
          read -ra comps <<< "$dir"
          local n=''${#comps[@]} i j start=1 cand
          (( ''${base_count["''${comps[n-1]}"]:-0} > 1 )) && start=2
          for ((i = start; i <= n; i++)); do
            cand=""
            for ((j = n - i; j < n; j++)); do cand+="-''${comps[j]}"; done
            cand=''${cand#-}
            cand=''${cand//./_}
            if [[ -z ''${taken_names[$cand]+x} ]]; then
              taken_names["$cand"]=1
              sname=$cand
              return 0
            fi
          done
          # Path components exhausted: disambiguate with a short hash.
          cand="''${cand//./_}-$(printf '%s' "$dir" | cksum | cut -d' ' -f1)"
          taken_names["$cand"]=1
          sname=$cand
        }
        for dir in "''${dirs[@]}"; do
          session_name "$dir"
          dir_name["$dir"]=$sname
        done

        # Pick a directory with fzf: existing sessions are marked ●.
        if [[ $# -eq 0 ]]; then
          lines=()
          for dir in "''${dirs[@]}"; do
            if [[ -n ''${existing_names["''${dir_name[$dir]}"]+x} ]]; then
              lines+=("● $dir")
            else
              lines+=("  $dir")
            fi
          done
          selected=$(printf '%s\n' "''${lines[@]}" | fzf --prompt='ts ▍ ') || true
          [[ -n $selected ]] || exit 0
          selected="''${selected#● }" # strip the ● marker
          selected="''${selected#  }" # strip the indent marker
        fi

        name=''${dir_name[$selected]}

        # Create the session if missing (also starts the server if needed),
        # then attach (outside tmux) or switch (inside tmux).
        if ! tmux has-session -t="$name" 2>/dev/null; then
          tmux new-session -ds "$name" -c "$selected"
        fi

        if [[ -n ''${TMUX:-} ]]; then
          tmux switch-client -t "$name"
        else
          tmux attach-session -t "$name"
        fi
      '';
    };
  };
}

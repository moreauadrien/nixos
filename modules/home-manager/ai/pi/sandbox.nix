{ pkgs, ... }: {
  # Sandboxed pi coding agent: `pi` builds (if needed) and runs a rootless
  # podman container with the current directory mounted. The Containerfile is
  # embedded directly here so no external file is needed.
  # Requires virtualisation.podman (enabled in modules/nixos/virtualisation.nix).
  home.packages = [
    (pkgs.writeShellScriptBin "pi" ''
      #!/usr/bin/env bash
      set -euo pipefail

      IMAGE="sandboxed-pi"
      CONTAINERFILE="''${HOME}/.config/pi-agent/Containerfile"

      if ! podman image exists "$IMAGE" 2>/dev/null; then
        echo "Building image $IMAGE..."
        podman build -t "$IMAGE" -f "$CONTAINERFILE" "$(dirname "$CONTAINERFILE")"
      fi

      # home-manager place les extensions gérées en symlinks vers /nix/store
      # (absent du conteneur) -> on copie les fichiers déréférencés dans un
      # vrai dossier et on le monte par-dessus le répertoire des extensions.
      EXT_DIR="''${HOME}/.cache/pi-agent/extensions"
      # On repart d'un dossier propre : cp -L préserve le mode 444 des
      # fichiers du /nix/store, une copie précédente serait read-only.
      rm -rf "$EXT_DIR"
      mkdir -p "$EXT_DIR"
      for f in "''${HOME}"/.pi/agent/extensions/*; do
        [ -e "$f" ] || continue
        cp -rL "$f" "$EXT_DIR/"
      done

      # Le dossier dans le conteneur porte le nom du dossier hôte courant.
      DIR_NAME="$(basename "$(pwd)")"
      [ "$DIR_NAME" = / ] && DIR_NAME=workspace

      # Herdr voit le wrapper, pas le vrai processus dans le conteneur :
      # on pose HERDR_AGENT sur la commande du wrapper elle-même (processus
      # hôte de premier plan), pas à l'intérieur du conteneur.
      exec env HERDR_AGENT=pi podman run -it --rm \
        -e PONYTAIL_HIDE_STATUS=1 \
        -w "/$DIR_NAME" \
        -v "$(pwd)":"/$DIR_NAME" \
        -v "$HOME/.pi":/root/.pi \
        -v "$EXT_DIR":/root/.pi/agent/extensions:ro \
        "$IMAGE"
    '')
  ];

  home.file.".config/pi-agent/Containerfile".text = ''
    # syntax=docker/dockerfile:1
    FROM nixos/nix:latest

    RUN mkdir -p /etc/nix && \
        echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

    RUN nix-channel --remove nixpkgs && \
        nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs && \
        nix-channel --update

    RUN nix profile add nixpkgs#pi-coding-agent
    RUN nix profile add nixpkgs#devenv
    RUN nix profile add nixpkgs#tmux
    RUN nix profile add nixpkgs#ripgrep

    ENV PATH="/root/.nix-profile/bin:''${PATH}"

    CMD ["pi"]
  '';
}

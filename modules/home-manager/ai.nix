{
  pkgs,
  pkgs-unstable,
  ...
}: {
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
        podman build -t "$IMAGE" -f "$CONTAINERFILE" "$CONTAINERFILE"
      fi

      exec podman run -it --rm \
        -v "$(pwd)":/workspace \
        -v "$HOME/.pi":/root/.pi \
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

    RUN nix profile install nixpkgs#pi-coding-agent
    RUN nix profile install nixpkgs#devenv
    RUN nix profile install nixpkgs#tmux
    RUN nix profile install nixpkgs#ripgrep

    ENV PATH="/root/.nix-profile/bin:''${PATH}"

    WORKDIR /workspace

    CMD ["pi"]
  '';

  programs.opencode = {
    enable = true;
    extraPackages = with pkgs; [
      wl-clipboard
      mcp-nixos
    ];

    settings = {
      plugin = ["@mohak34/opencode-notifier@latest"];
      mcp = {
        nixos = {
          type = "local";
          command = ["${pkgs.mcp-nixos}/bin/mcp-nixos"];
          enabled = true;
        };
      };
    };
  };
}

{
  pkgs,
  pkgs-unstable,
  ...
}: let
  # Docker image with pi + nix + devenv for sandboxed agentic workflow
  piImage = pkgs-unstable.dockerTools.buildLayeredImage {
    name = "pi-agent";
    tag = "latest";
    maxLayers = 100;
    contents = with pkgs-unstable; [
      bashInteractive
      coreutils-full
      pi-coding-agent
      nix
      devenv
      git
      curl
      cacert
      gnugrep
      gnutar
      gzip
      xz
    ];
    config = {
      Env = [
        "PATH=/bin"
        "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
        "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
        "NIX_REMOTE=daemon"
      ];
      WorkingDir = "/work";
      Entrypoint = ["pi"];
    };
  };

  pi-container = pkgs-unstable.writeShellScriptBin "pi-container" ''
    #!/usr/bin/env bash
    set -euo pipefail

    IMAGE="${piImage}"
    IMAGE_NAME="pi-agent:latest"

    # Ensure cache directories exist
    mkdir -p "$HOME"/.cache/nix "$HOME"/.cache/devenv

    # Load image into Docker if not already present
    if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
      echo "Loading pi-agent container image..." >&2
      docker load < "$IMAGE"
    fi

    exec docker run --rm -it \
      --name "pi-$$" \
      -v "$(pwd):/work" \
      -v "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket" \
      -v "$HOME/.cache/nix:/root/.cache/nix" \
      -v "$HOME/.cache/devenv:/root/.cache/devenv" \
      -e "HOME=/root" \
      -e "NIX_REMOTE=daemon" \
      -e "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt" \
      -e "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt" \
      -e "PI_API_KEY" \
      -e "ANTHROPIC_API_KEY" \
      -e "OPENAI_API_KEY" \
      -e "OPENROUTER_API_KEY" \
      --cap-drop=ALL \
      --security-opt=no-new-privileges \
      pi-agent "$@"
  '';
in {
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

  home.packages = with pkgs-unstable; [
    pi-container
    nodejs_24
  ];

  home.shellAliases = {
    pi = "pi-container";
  };

  # Clean up old fence-managed config files
  home.file = {
    ".config/fence/fence.json".enable = false;
    ".config/fence/pi.json".enable = false;
  };
}

{
  pkgs,
  pkgs-unstable,
  ...
}: 
let
  # Icône pi pour les notifications (favicon officiel pi.dev).
  pi-icon-svg = pkgs.writeText "pi-icon.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 800">
      <rect width="800" height="800" rx="120" fill="#09090b"/>
      <path fill="#fff" fill-rule="evenodd" d="
        M165.29 165.29
        H517.36
        V400
        H400
        V517.36
        H282.65
        V634.72
        H165.29
        Z
        M282.65 282.65
        V400
        H400
        V282.65
        Z
      "/>
      <path fill="#fff" d="M517.36 400 H634.72 V634.72 H517.36 Z"/>
    </svg>
  '';

  # gdk-pixbuf (utilisé par mako) rend le PNG nativement mais a besoin du
  # loader librsvg pour le SVG -> on convertit au build.
  pi-icon-png = pkgs.runCommand "pi-icon.png" {} ''
    ${pkgs.imagemagick}/bin/magick ${pi-icon-svg} -resize 128x128 "$out"
  '';

  # Proxy de notifications pi : lit la FIFO ~/.pi/notify.fifo (une ligne
  # "titre\tcorps" par notification, écrite par l'extension pi ci-dessous,
  # montée dans le conteneur via ~/.pi) et émet une notification desktop.
  pi-notify-proxy = pkgs.writeShellScriptBin "pi-notify-proxy" ''
    #!/usr/bin/env bash
    FIFO="''${HOME}/.pi/notify.fifo"
    [ -p "$FIFO" ] || mkfifo "$FIFO"
    while true; do
      # read échoue (EOF) quand le dernier writer ferme la FIFO -> on réouvre.
      IFS=$'\t' read -r title body < "$FIFO" || continue
      ${pkgs.libnotify}/bin/notify-send -a pi -i "${pi-icon-png}" "$title" "''${body:-}"
    done
  '';
in {
  # Copie du SVG à côté des autres fichiers pi (le proxy utilise le PNG).
  home.file.".config/pi-agent/pi-icon.svg".source = pi-icon-svg;

  # Sandboxed pi coding agent: `pi` builds (if needed) and runs a rootless
  # podman container with the current directory mounted. The Containerfile is
  # embedded directly here so no external file is needed.
  # Requires virtualisation.podman (enabled in modules/nixos/virtualisation.nix).
  home.packages = [
    pi-notify-proxy
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

      exec podman run -it --rm \
        -v "$(pwd)":/workspace \
        -v "$HOME/.pi":/root/.pi \
        -v "$EXT_DIR":/root/.pi/agent/extensions:ro \
        "$IMAGE"
    '')
  ];

  # Extension pi : écrit dans la FIFO quand pi a fini de travailler ou attend
  # une entrée utilisateur. Auto-découverte (montée comme /root/.pi dans le
  # conteneur). Ouverture en O_NONBLOCK : si aucun proxy ne lit la FIFO,
  # l'open échoue et on ignore silencieusement (jamais de blocage).
  home.file.".pi/agent/extensions/desktop-notify.ts".text = ''
    import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
    import { constants, closeSync, existsSync, openSync, writeSync } from "node:fs";
    import { execFileSync } from "node:child_process";
    import { homedir } from "node:os";
    import { basename, join } from "node:path";

    const FIFO = join(homedir(), ".pi", "notify.fifo");

    function send(body: string) {
      try {
        if (!existsSync(FIFO)) execFileSync("mkfifo", [FIFO]);
        const fd = openSync(FIFO, constants.O_WRONLY | constants.O_NONBLOCK);
        try {
          writeSync(fd, `pi\t''${body.replace(/[\t\n]/g, " ")}\n`);
        } finally {
          closeSync(fd);
        }
      } catch {
        // Pas de lecteur (proxy arrêté) : pas grave, on ignore.
      }
    }

    export default function (pi: ExtensionAPI) {
      pi.on("agent_settled", async (_event, ctx) => {
        send(`Terminé — ''${basename(ctx.cwd)} attend ton retour`);
      });

      pi.on("ui_prompt_start", async (event) => {
        send(`Attend ton input — ''${event.title ?? event.kind}`);
      });
    }
  '';

  # Extension pi : remplace le provider "opencode" par un clone filtré qui ne
  # garde que les modèles gratuits (coût 0 en input et output).
  home.file.".pi/agent/extensions/opencode-free.ts".text = ''
    // Provider "opencode" limité aux modèles gratuits (coût 0 en input et output).
    import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

    export default function (pi: ExtensionAPI) {
      let done = false;
      pi.on("session_start", async (_event, ctx) => {
        if (done) return;
        const provider = ctx.modelRegistry.getProvider("opencode");
        if (!provider) return;
        const clone = Object.create(
          Object.getPrototypeOf(provider),
          Object.getOwnPropertyDescriptors(provider),
        );
        clone.filterModels = (models: readonly any[]) =>
          models.filter((m) => !m.cost || (m.cost.input === 0 && m.cost.output === 0));
        pi.registerProvider(clone);
        done = true;
      });
    }
  '';

  # Proxy lancé en service utilisateur : il consomme la FIFO et émet les
  # notifications desktop via mako.
  systemd.user.services.pi-notify = {
    Unit.Description = "pi notification proxy (FIFO -> notify-send)";
    Service = {
      ExecStart = "${pi-notify-proxy}/bin/pi-notify-proxy";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = ["default.target"];
  };

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

{ self, ... }: {
  flake.nixosModules.pi =
    { pkgs, ... }:
    let
      # pi icon for notifications (official pi.dev favicon).
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

      # pi notification proxy: reads the ~/.pi/notify.fifo FIFO (one empty line
      # per notification, written by the pi extension below, mounted in the
      # container via ~/.pi) and emits a desktop notification (title "π").
      pi-notify-proxy = pkgs.writeShellScriptBin "pi-notify-proxy" ''
        #!/usr/bin/env bash
        FIFO="''${HOME}/.pi/notify.fifo"
        [ -p "$FIFO" ] || mkfifo "$FIFO"
        while true; do
          # read fails (EOF) when the last writer closes the FIFO -> reopen.
          read -r < "$FIFO" || continue
          ${pkgs.libnotify}/bin/notify-send -a pi -i "${pi-icon-svg}" "π" "Done."
        done
      '';

      # Sandbox container image, built at deploy time by Nix (dockerTools):
      # the wrapper just does a `podman load` on first run, no runtime build
      # or downloads on the tmpfs.
      pi-image = pkgs.dockerTools.buildImage {
        name = "sandboxed-pi";
        tag = "latest";
        copyToRoot = pkgs.buildEnv {
          name = "pi-image-root";
          paths = [
            pkgs.bash
            pkgs.coreutils
            pkgs.nix
            pkgs.devenv
            pkgs.tmux
            pkgs.git
            pkgs.gnugrep
            pkgs.coreutils
            pkgs.ripgrep
            pkgs.pi-coding-agent
            pkgs.cacert
            (pkgs.writeTextDir "etc/nix/nix.conf" ''
              experimental-features = nix-command flakes
            '')
            (pkgs.runCommand "ca-symlink" {} ''
              mkdir -p $out/etc/ssl/certs
              ln -s ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
                $out/etc/ssl/certs/ca-certificates.crt
            '')
          ];
        };
        config = {
          Env = [
            "PATH=/bin"
            "HOME=/root"
            "USER=root"
            "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
          ];
          Cmd = [ "pi" ];
        };
      };

      # Sandboxed pi coding agent: `pi` loads the image (if needed) then starts
      # a rootless podman container with the current directory mounted.
      pi-wrapper = pkgs.writeShellScriptBin "pi" ''
        #!/usr/bin/env bash
        set -euo pipefail

        IMAGE="sandboxed-pi"
        # Marker remembering which nix store image was last loaded: podman
        # keeps the old image tagged sandboxed-pi:latest after a rebuild, so
        # `podman image exists` alone would never pick up changes (e.g. new
        # executables added to pi-image).
        STATE="$HOME/podman/.sandboxed-pi-image"

        if [ "$(cat "$STATE" 2>/dev/null || true)" != "${pi-image}" ]; then
          echo "Loading image $IMAGE..."
          # podman doesn't create $graphroot/tmp itself (used as staging by
          # image_copy_tmp_dir="storage").
          mkdir -p "$HOME/podman/storage/tmp"
          podman load -i "${pi-image}"
          printf '%s' "${pi-image}" > "$STATE"
        fi

        # hjem places managed extensions as symlinks to /nix/store (absent from
        # the container) -> copy the dereferenced files into a real directory
        # and mount it over the extensions directory.
        EXT_DIR="''${HOME}/.cache/pi-agent/extensions"
        # Start from a clean directory: cp -L preserves the 444 mode of
        # /nix/store files, a previous copy would be read-only.
        rm -rf "$EXT_DIR"
        mkdir -p "$EXT_DIR"
        for f in "''${HOME}"/.pi/agent/extensions/*; do
          [ -e "$f" ] || continue
          cp -rL "$f" "$EXT_DIR/"
        done

        # The directory in the container is named after the current host directory.
        DIR_NAME="$(basename "$(pwd)")"
        [ "$DIR_NAME" = / ] && DIR_NAME=workspace

        exec podman run -it --rm \
          -e PONYTAIL_HIDE_STATUS=1 \
          -w "/$DIR_NAME" \
          -v "$(pwd)":"/$DIR_NAME" \
          -v "$HOME/.pi":/root/.pi \
          -v "$EXT_DIR":/root/.pi/agent/extensions:ro \
          "$IMAGE"
      '';
    in
    {
      # Requis par le wrapper (conteneur rootless).
      virtualisation.podman.enable = true;

      hjem.users.adrien = {
        packages = [ pi-wrapper ];
        files = {
          ".config/pi-agent/pi-icon.svg".source = pi-icon-svg;

          # Rootless podman: graphroot on persistent disk (via the preservation
          # bind mount, see tallyhoPreservation) and image staging in the
          # storage instead of /var/tmp (tmpfs -> "no space left on device"
          # on podman load).
          ".config/containers/containers.conf".text = ''
            [engine]
            image_copy_tmp_dir = "storage"
          '';
          ".config/containers/storage.conf".text = ''
            [storage]
            driver = "overlay"
            graphroot = "/home/adrien/podman/storage"
          '';

          # pi extension: writes to the FIFO when pi finishes working or waits
          # for user input. Auto-discovered (mounted as /root/.pi in the
          # container). O_NONBLOCK open: if no proxy reads the FIFO, the
          # open fails and we silently ignore it.
          ".pi/agent/extensions/desktop-notify.ts".text = ''
            import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
            import { constants, closeSync, existsSync, openSync, writeSync } from "node:fs";
            import { execFileSync } from "node:child_process";
            import { homedir } from "node:os";
            import { join } from "node:path";

            const FIFO = join(homedir(), ".pi", "notify.fifo");

            // An empty line is enough: title and body are set by the proxy.
            function send() {
              try {
                if (!existsSync(FIFO)) execFileSync("mkfifo", [FIFO]);
                const fd = openSync(FIFO, constants.O_WRONLY | constants.O_NONBLOCK);
                try {
                  writeSync(fd, "\n");
                } finally {
                  closeSync(fd);
                }
              } catch {
                // No reader (proxy stopped): not a problem, ignore.
              }
            }

            export default function (pi: ExtensionAPI) {
              pi.on("agent_settled", async () => {
                send();
              });

              pi.on("ui_prompt_start", async () => {
                send();
              });
            }
          '';
        };
      };

      # Proxy run as a user service: it consumes the FIFO and emits the
      # desktop notifications.
      systemd.user.services.pi-notify = {
        description = "pi notification proxy (FIFO -> notify-send)";
        serviceConfig = {
          ExecStart = "${pi-notify-proxy}/bin/pi-notify-proxy";
          Restart = "always";
          RestartSec = 2;
        };
        wantedBy = [ "default.target" ];
      };
    };
}

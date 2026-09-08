{pkgs, ...}: let
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

  # Proxy de notifications pi : lit la FIFO ~/.pi/notify.fifo (une ligne vide
  # par notification, écrite par l'extension pi ci-dessous, montée dans le
  # conteneur via ~/.pi) et émet une notification desktop (titre "π").
  pi-notify-proxy = pkgs.writeShellScriptBin "pi-notify-proxy" ''
    #!/usr/bin/env bash
    FIFO="''${HOME}/.pi/notify.fifo"
    [ -p "$FIFO" ] || mkfifo "$FIFO"
    while true; do
      # read échoue (EOF) quand le dernier writer ferme la FIFO -> on réouvre.
      read -r < "$FIFO" || continue
      ${pkgs.libnotify}/bin/notify-send -a pi -i "${pi-icon-svg}" "π" "Done."
    done
  '';
in {
  # Copie du SVG à côté des autres fichiers pi (le proxy utilise le SVG).
  home.file.".config/pi-agent/pi-icon.svg".source = pi-icon-svg;

  # Extension pi : écrit dans la FIFO quand pi a fini de travailler ou attend
  # une entrée utilisateur. Auto-découverte (montée comme /root/.pi dans le
  # conteneur). Ouverture en O_NONBLOCK : si aucun proxy ne lit la FIFO,
  # l'open échoue et on ignore silencieusement (jamais de blocage).
  home.file.".pi/agent/extensions/desktop-notify.ts".text = ''
    import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
    import { constants, closeSync, existsSync, openSync, writeSync } from "node:fs";
    import { execFileSync } from "node:child_process";
    import { homedir } from "node:os";
    import { join } from "node:path";

    const FIFO = join(homedir(), ".pi", "notify.fifo");

    // Une ligne vide suffit : titre et corps sont fixés par le proxy.
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
        // Pas de lecteur (proxy arrêté) : pas grave, on ignore.
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
}

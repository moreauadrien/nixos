# Quickshell bar: binary + its config (self-contained feature).
{ ... }: {
  flake.nixosModules.quickshell = { pkgs, ... }: let
    chargeLimit = pkgs.writeShellScriptBin "charge-limit" ''
      set -eu
      [ "$#" -eq 1 ] || exit 2
      case "$1" in get|80|100) ;; *) exit 2 ;; esac
      found=0
      for path in /sys/class/power_supply/BAT*/charge_control_end_threshold; do
        [ -e "$path" ] || continue
        found=1
        if [ "$1" = get ]; then
          read -r limit < "$path"
          printf '%s\n' "$limit"
          exit 0
        fi
        printf '%s\n' "$1" > "$path"
      done
      [ "$found" -eq 1 ] || { [ "$1" != get ] && exit 0; exit 1; }
    '';
  in {
    environment.systemPackages = [ pkgs.quickshell pkgs.libnotify chargeLimit ];

    # Only these two values may be written without a password.
    security.sudo.extraRules = [{
      users = [ "adrien" ];
      commands = map (limit: {
        command = "/run/current-system/sw/bin/charge-limit ${limit}";
        options = [ "NOPASSWD" ];
      }) [ "80" "100" ];
    }];

    # A 100% override is session-only; restore 80% at every boot.
    systemd.services.charge-limit-default = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${chargeLimit}/bin/charge-limit 80";
      };
    };

    hjem.users.adrien.files.".config/quickshell".source = ./config;
  };
}

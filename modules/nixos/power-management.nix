{pkgs, ...}: let
  set-battery-threshold = pkgs.writeShellScriptBin "set-battery-threshold" ''
    set -e
    if [ "$#" -ne 1 ] || { [ "$1" != "80" ] && [ "$1" != "100" ]; }; then
      echo "Usage: set-battery-threshold <80|100>" >&2
      exit 1
    fi
    printf '%s' "$1" > /sys/class/power_supply/BAT1/charge_control_end_threshold
  '';

  batteryGroup = "battery";
in {
  powerManagement = {
    enable = true;
    powertop.enable = false;
  };

  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 20;
    };
  };

  users.groups.battery = {};

  systemd.tmpfiles.rules = [
    "z /sys/class/power_supply/BAT1/charge_control_end_threshold 0664 root ${batteryGroup} - -"
  ];

  systemd.services.battery-charge-threshold = {
    description = "Set battery charge control end threshold to 80%";
    wantedBy = ["multi-user.target"];
    after = ["sysinit.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'printf 80 > /sys/class/power_supply/BAT1/charge_control_end_threshold'";
    };
  };

  environment.systemPackages = [set-battery-threshold];
}

# Power management: battery/AC handling and suspend support.
{ ... }: {
  flake.nixosModules.power-management = { pkgs, ... }: {
    powerManagement.enable = true;

    services.thermald.enable = true;

    # services.tlp = {
    #   enable = true;
    #   settings = {
    #     CPU_SCALING_GOVERNOR_ON_AC = "powersave";
    #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

    #     CPU_ENERGY_PERF_POLICY_ON_AC = "balance_power";
    #     CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

    #     CPU_BOOST_ON_AC = 1;
    #     CPU_BOOST_ON_BAT = 0;

    #     CPU_MIN_PERF_ON_AC = 0;
    #     CPU_MAX_PERF_ON_AC = 80;
    #     CPU_MIN_PERF_ON_BAT = 0;
    #     CPU_MAX_PERF_ON_BAT = 30;

    #     STOP_CHARGE_THRESH_BAT0 = 80;
    #   };
    # };
    services.auto-cpufreq.enable = true;
    services.auto-cpufreq.settings = {
      battery = { governor = "powersave"; turbo = "never"; };
      charger = { governor = "performance"; turbo = "auto"; };
    };
  };
}


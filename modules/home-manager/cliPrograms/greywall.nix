{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.greywall;
in
{
  options.programs.greywall = {
    enable = lib.mkEnableOption "Greywall sandbox for AI coding agents";
    package = lib.mkPackageOption pkgs "greywall" { };
    greyproxyPackage = lib.mkPackageOption pkgs "greyproxy" { };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      cfg.greyproxyPackage
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      pkgs.bubblewrap
      pkgs.socat
      pkgs.xdg-dbus-proxy
      pkgs.libsecret
    ];

    systemd.user.services.greyproxy = {
      Unit = {
        Description = "Greyproxy - network proxy and dashboard for Greywall";
        After = [ "network.target" ];
      };
      Service = {
        ExecStart = "${cfg.greyproxyPackage}/bin/greyproxy serve";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}

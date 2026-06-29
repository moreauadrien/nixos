{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.greywall;
in
{
  options.services.greywall = {
    enable = lib.mkEnableOption "Greywall sandbox system dependencies (bubblewrap, socat, etc.)";
    package = lib.mkPackageOption pkgs "greywall" { };
    enableOptionalDeps = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install optional dependencies (xdg-dbus-proxy, libsecret)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      [
        pkgs.bubblewrap
        pkgs.socat
      ]
      ++ lib.optionals cfg.enableOptionalDeps [
        pkgs.xdg-dbus-proxy
        pkgs.libsecret
      ];
  };
}

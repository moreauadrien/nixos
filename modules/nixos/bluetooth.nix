{pkgs, ...}: {
  hardware.bluetooth.enable = true;

  hardware.bluetooth.settings = {
    General = {
      ControllerMode = "dual";
      FastConnectable = "true";
    };
  };

  environment.systemPackages = with pkgs; [
    bluetui
  ];

  # bluez >= 5.86 fournit déjà l'unité mpris-proxy.service avec son ExecStart :
  # on se contente de l'activer (sinon -> doublon ExecStart et unité "bad-setting").
  systemd.user.units."mpris-proxy.service".wantedBy = ["default.target"];
}

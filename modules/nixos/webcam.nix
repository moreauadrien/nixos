{ pkgs, ...}: {
  hardware.ipu6 = {
    enable = true;
    platform = "ipu6ep";
  };
  hardware.enableRedistributableFirmware = true;

  users.users.adrien.extraGroups = [ "video" ];

  environment.systemPackages = with pkgs; [
    v4l-utils  # Pour lister et tester les caméras
    ffmpeg     # Pour capturer de la vidéo
    cheese     # Application simple pour tester la caméra (optionnel)
  ];
}

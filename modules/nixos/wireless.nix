{pkgs, ...}: {
  networking.wireless.iwd.enable = true;

  environment.systemPackages = with pkgs; [
    impala
  ];
}

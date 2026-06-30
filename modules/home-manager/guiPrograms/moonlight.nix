{ pkgs, ... }: {
  home.packages = with pkgs; [
    moonlight-qt

    # Support VAAPI
    libva
    libva-utils

    # Support VDPAU
    libvdpau
    libvdpau-va-gl

    intel-media-driver
  ];
}

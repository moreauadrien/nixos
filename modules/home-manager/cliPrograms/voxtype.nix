{pkgs, ...}: {
  home.packages = with pkgs; [
    voxtype-vulkan
  ];

  # nixpkgs build voxtype sans feature OSD (osd-gtk4/osd-native absentes),
  # voxtype-osd échoue sinon -> on le désactive explicitement.
  home.file.".config/voxtype/config.toml".text = ''
    [osd]
    enabled = false
  '';
}

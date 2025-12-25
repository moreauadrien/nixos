{...}: {
  programs.virt-manager.enable = true;
  virtualisation.libvirtd.enable = true;

  virtualisation.docker = {
    enable = true;
  };

  users.users.adrien.extraGroups = ["docker"];
}

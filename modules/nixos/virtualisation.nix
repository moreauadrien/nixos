{pkgs, ...}: {
  environment.systemPackages = [pkgs.smolvm];

  programs.virt-manager.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      vhostUserPackages = with pkgs; [virtiofsd];
      swtpm.enable = true;
    };
  };

  virtualisation.docker = {
    enable = false;
  };

  # Rootless podman, used by the sandboxed "pi" agent container
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
  };

  systemd.services.libvirt-default-network = {
    description = "Start libvirt default network";
    after = ["libvirtd.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.libvirt}/bin/virsh net-start default";
      ExecStop = "${pkgs.libvirt}/bin/virsh net-destroy default";
      User = "root";
    };
  };

  users.users.adrien = {
    extraGroups = [
      "kvm"
    ];
    # subuid/subgid ranges required by rootless podman
    autoSubUidGidRange = true;
  };
}

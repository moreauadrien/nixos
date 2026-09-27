# Virtualization stack: virt-manager GUI on top of QEMU/KVM.
{ ... }: {
  flake.nixosModules.virt-manager = { pkgs, ... }: {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        # Full-system emulation for non-x86 guests (aarch64, riscv64, ...).
        swtpm.enable = true;
        # Note: OVMF firmware is included in the default qemu package
        # since NixOS 24.05, no need to enable it explicitly.
      };
    };

    # Spice remote display + USB redirection helpers for virt-manager.
    programs.virt-manager.enable = true;

    environment.systemPackages = with pkgs; [
      virt-viewer
      spice
      spice-gtk
      virtiofsd
    ];

    # Allow the main user group to manage VMs without root prompts.
    users.groups.libvirtd.members = [ "adrien" ];
  };
}
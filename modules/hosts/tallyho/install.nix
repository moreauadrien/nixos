# Installer script as a flake package: `nix run .#install` (or `nix run 'git+...#install'`
# from the installer ISO). The bash lives in ./install.sh (import-tree only picks .nix).
{ ... }: {
  perSystem = { pkgs, ... }: {
    packages.install = pkgs.writers.writeBashBin "install" ''
      export PATH=${pkgs.lib.makeBinPath [
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.gawk
        pkgs.git
        pkgs.util-linux
        pkgs.gum
        pkgs.openssl
        pkgs.cryptsetup
        pkgs.nixos-install-tools
      ]}:$PATH
      ${builtins.readFile ./install.sh}
    '';
  };
}

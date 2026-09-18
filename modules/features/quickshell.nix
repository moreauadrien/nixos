# Quickshell bar: binary + its config (self-contained feature).
{ self, ... }: {
  flake.nixosModules.quickshell = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.quickshell ];

    hjem.users.adrien.files.".config/quickshell".source = "${self}/dotfiles/quickshell";
  };
}

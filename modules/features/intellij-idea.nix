# IntelliJ IDEA (unified distribution).
{
  flake.nixosModules.intellij-idea = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.intellij-idea ];
  };
}

# OrcaSlicer 3D printing slicer.
{
  flake.nixosModules.orca-slicer = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.orca-slicer ];
  };
}

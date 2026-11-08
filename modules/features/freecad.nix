# FreeCAD parametric 3D modeler.
{
  flake.nixosModules.freecad = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.freecad ];
  };
}

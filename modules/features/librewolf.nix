# LibreWolf browser.
{ ... }: {
  flake.nixosModules.librewolf = {
    programs.librewolf.enable = true;
  };
}

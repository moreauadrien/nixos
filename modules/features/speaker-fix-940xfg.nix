{ inputs, ... }:
{
  flake.nixosModules.speaker-fix-940xfg = { ... }: {
    imports = [ "${inputs.samsung-fixes}/nixos/speaker-fix-940xfg.nix" ];
    hardware.samsungGalaxyBook.speakerFix940xfg.enable = true;
  };
}

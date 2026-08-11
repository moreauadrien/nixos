{inputs, ...}: let
  startpage_preferences = import ./startpage-preferences.nix;
in {
  imports = [
    inputs.walker.homeManagerModules.default
  ];

  programs.walker = {
    enable = true;
  };

  programs.elephant.provider.websearch.settings = {
    entries = [
      {
        name = "Startpage";
        default = true;
        url = "https://www.startpage.com/sp/search?prfe=${startpage_preferences}&query=%TERM%";
      }
      {
        name = "NixOS Packages";
        prefix = "nix:";
        url = "https://search.nixos.org/packages?channel=unstable&query=%TERM%";
      }
    ];
  };
}

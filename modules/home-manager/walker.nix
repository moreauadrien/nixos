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
        name = "DuckDuckGo";
        default = true;
        url = "https://noai.duckduckgo.com/?q=%TERM%";
      }
      {
        name = "Startpage";
        url = "https://www.startpage.com/sp/search?prfe=${startpage_preferences}&query=%TERM%";
      }
      {
        name = "Brave Search";
        prefix = "brave:";
        url = "https://search.brave.com/search?q=%TERM%";
      }
      {
        name = "Kagi";
        prefix = "kagi:";
        url = "https://kagi.com/search?q=%TERM%";
      }
      {
        name = "NixOS Packages";
        prefix = "nix:";
        url = "https://search.nixos.org/packages?channel=unstable&query=%TERM%";
      }
    ];
  };
}

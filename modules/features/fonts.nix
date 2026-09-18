# Fonts and fontconfig defaults.
{ ... }: {
  flake.nixosModules.fonts = { pkgs, ... }: {
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      ubuntu-sans
    ];

    fonts.fontconfig.defaultFonts = {
      serif = [ "Ubuntu Sans" ];
      sansSerif = [ "Ubuntu Sans" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
    };
  };
}

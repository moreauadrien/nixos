# Fonts and fontconfig defaults.
{ ... }: {
  flake.nixosModules.fonts = { pkgs, ... }: {
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      ubuntu-sans
      noto-fonts-color-emoji
    ];

    fonts.fontconfig.defaultFonts = {
      serif = [ "Ubuntu Sans" ];
      sansSerif = [ "Ubuntu Sans" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
      emoji = [ "Noto Color Emoji" ];
    };

    fonts.fontconfig.localConf = ''
      <match target="pattern">
        <test name="family" compare="eq">
          <string>JetBrainsMono Nerd Font</string>
        </test>
        <edit name="family" mode="append" binding="strong">
          <string>Noto Color Emoji</string>
        </edit>
      </match>
    '';
  };
}

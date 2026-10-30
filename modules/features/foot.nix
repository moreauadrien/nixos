# Foot terminal with the same font and Tokyo Night palette as Alacritty.
{ ... }: {
  flake.nixosModules.foot = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.foot ];

    # Hide auxiliary launchers while keeping the client/server commands available.
    hjem.users.adrien.files.".local/share/applications/footclient.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Foot Client
      Hidden=true
    '';
    hjem.users.adrien.files.".local/share/applications/foot-server.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Foot Server
      Hidden=true
    '';

    hjem.users.adrien.files.".config/foot/foot.ini".text = ''
      [main]
      font=JetBrainsMono Nerd Font:size=17
      pad=0x0

      [colors-dark]
      background=1a1b26
      foreground=a9b1d6
      regular0=32344a
      regular1=f7768e
      regular2=9ece6a
      regular3=e0af68
      regular4=7aa2f7
      regular5=ad8ee6
      regular6=449dab
      regular7=787c99
      bright0=444b6a
      bright1=ff7a93
      bright2=b9f27c
      bright3=ff9e64
      bright4=7da6ff
      bright5=bb9af7
      bright6=0db9d7
      bright7=acb0d0

      [text-bindings]
      \x1b[13;2u=Shift+Return
    '';
  };
}

# VLC media player.
{
  flake.nixosModules.vlc = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.vlc ];
  };
}

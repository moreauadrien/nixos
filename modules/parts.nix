# Set of supported systems (kept in a module, like voidarc's parts.nix,
# so flake.nix stays minimal).
{ ... }: {
  systems = [ "x86_64-linux" ];
}

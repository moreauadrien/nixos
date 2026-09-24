# Elephant launcher backend: binary + websearch provider config.
{ ... }: {
  flake.nixosModules.elephant = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.elephant ];

    # Websearch provider entry (TOML) for the nixpkgs package search.
    hjem.users.adrien.files.".config/elephant/websearch.toml".text = ''
      [[entries]]
      default = false
      name = "nixpkgs"
      url = "https://search.nixos.org/packages?channel=unstable&query=%TERM%"
      icon = "nix-snowflake"
    '';
  };
}

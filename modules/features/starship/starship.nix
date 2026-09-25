# Starship prompt: pure-preset config + bash init (single file feature).
{ ... }: {
  flake.nixosModules.starship = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.starship ];

    hjem.users.adrien = {
      # Preset generated with `starship preset pure-preset`.
      files.".config/starship.toml".source = ./pure-preset.toml;

      # NixOS bash already sources /etc/bashrc for interactive shells (SYS_BASHRC),
      # so ~/.bashrc only needs the prompt init.
      files.".bashrc".text = ''
        eval "$(starship init bash)"
      '';
    };
  };
}
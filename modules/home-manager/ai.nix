{
  pkgs,
  pkgs-unstable,
  ...
}: {
  # Sandboxed pi coding agent: `pi` launches a rootless podman container
  # with the current directory mounted. See pi/pi.sh and pi/Containerfile.
  # Requires virtualisation.podman (enabled in modules/nixos/virtualisation.nix).
  home.packages = [
    (pkgs.writeShellScriptBin "pi" (builtins.readFile ./pi/pi.sh))
  ];

  home.file.".config/pi-agent/Containerfile".source = ./pi/Containerfile;

  programs.opencode = {
    enable = true;
    extraPackages = with pkgs; [
      wl-clipboard
      mcp-nixos
    ];

    settings = {
      plugin = ["@mohak34/opencode-notifier@latest"];
      mcp = {
        nixos = {
          type = "local";
          command = ["${pkgs.mcp-nixos}/bin/mcp-nixos"];
          enabled = true;
        };
      };
    };
  };
}

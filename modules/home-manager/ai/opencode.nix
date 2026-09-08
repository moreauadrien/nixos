{pkgs, ...}: {
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

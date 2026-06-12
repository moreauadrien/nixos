{pkgs, ...}: {
  programs.opencode = {
    enable = true;
    extraPackages = with pkgs; [
    ];

    settings = {
      plugin = ["@mohak34/opencode-notifier@latest"];
    };
  };
}

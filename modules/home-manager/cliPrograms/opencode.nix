{pkgs, ...}: {
  programs.opencode = {
    enable = true;
    extraPackages = with pkgs; [
      wl-clipboard
    ];

    settings = {
      plugin = ["@mohak34/opencode-notifier@latest"];
    };
  };
}

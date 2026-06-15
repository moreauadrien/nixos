{...}: {
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./scripts.nix
    ./cursor.nix
    ./walker.nix

    ./guiPrograms/alacritty.nix
    ./guiPrograms/whatsapp.nix
    ./guiPrograms/discord.nix
    ./guiPrograms/localsend.nix
    ./guiPrograms/firefox.nix
    ./guiPrograms/moonlight.nix
    ./guiPrograms/bruno.nix
    ./guiPrograms/obsidian.nix
    ./guiPrograms/mako.nix
    ./guiPrograms/mpv.nix
    ./guiPrograms/foliate.nix
    ./guiPrograms/brave.nix
    ./cliPrograms/opencode.nix
    ./cliPrograms/neovim.nix
    ./cliPrograms/git.nix

    ./kde_connect.nix
    #./cliPrograms/clangd.nix
  ];
}

# Audio: pipewire + wireplumber stack (wpctl in the Hyprland keybinds
# depends on it) plus wiremix, the TUI mixer for PipeWire.
{ pkgs, ... }: {
  flake.nixosModules.audio = {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };

    environment.systemPackages = with pkgs; [
      wiremix
    ];
  };
}
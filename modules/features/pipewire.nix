# Audio stack (pipewire + wireplumber): wpctl in the Hyprland keybinds depends on it.
{ ... }: {
  flake.nixosModules.pipewire = {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };
}

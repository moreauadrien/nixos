# OBS Studio: screen recording and streaming.
{ ... }: {
  flake.nixosModules.obs-studio = {
    # programs.obs-studio enables the bundled chromium CEF browser source.
    programs.obs-studio.enable = true;
  };
}
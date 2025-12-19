{pkgs, ...}: {
  services.pulseaudio.enable = false;

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # Uncomment the following line if you want to use JACK applications
    # jack.enable = true;
  };

  environment.systemPackages = with pkgs; [
    alsa-tools
  ];

  systemd.services.hda-verb-setup = {
    description = "Configure HDA verbs";
    wantedBy = ["multi-user.target"];
    after = ["sound.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = builtins.readFile ./hda-verb-setup;
  };
}

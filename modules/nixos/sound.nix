{pkgs, ...}: let
  speakerSetupScript = import ./internal_speaker_setup_script.nix {inherit pkgs;};
in {
  services.pulseaudio.enable = false;

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    alsa-tools
    wiremix
    speakerSetupScript
  ];

  systemd.services.hda-verb-setup = {
    description = "Initialize internal speaker";
    wantedBy = ["multi-user.target"];
    after = ["sound.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${speakerSetupScript}/bin/internal_speaker_setup";
      RemainAfterExit = true;
    };
  };
}

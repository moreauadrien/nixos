{pkgs, ...}: let
  speakerSetupScript = pkgs.writeShellScriptBin "internal_speaker_setup" ''
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! IMPORTANT NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! This script should only be used for troubleshooting and as a temporary solution while !!!"
    echo "!!! waiting for your device's support to be implemented in the kernel.                    !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo ""
    echo "This script will attempt to init and enable 4 speaker amps, but your device may only have 2, "
    echo "or it might not even have the speaker amp identifiers given in this script!"
    echo ""
    echo "For more information, see: https://github.com/joshuagrisham/galaxy-book2-pro-linux/tree/main/sound"
    echo "and/or: https://github.com/thesofproject/linux/issues/4055#issuecomment-2323411911"
    echo ""

    echo "Init front left speaker (0x38)"

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x38

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

  ## Disable the speaker

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xFF
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3A
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x80
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

  ## Init

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xE1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x12
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x6F
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x14
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x1B
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x1D
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x1F
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0xFE
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x21
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x10
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3D
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x05
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3F
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x03
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x50
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x2C
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x76
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0E
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x7C
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x4A
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x81
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x03
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0x99
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x03
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xA4
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0xB5
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xA5
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xBA
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x94
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

  ## Windows driver sets 0x89 to 0 after initializing the speaker but it seems like the value is already 0 and the speaker seems to work anyway without seting this here?
  ## But *just in case* and especially with other devices, set 0x89 to 0 again here to be sure...
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x89
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00

    echo "Init front right speaker (0x39)"

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x39

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

  ## Disable the speaker

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xFF
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3A
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x80
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

  ## Init

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xE1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x12
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x6F
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x14
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x1B
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x02 # 0x02 for right instead of 0x01 like on left
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x1D
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x02 # 0x02 for right instead of 0x01 like on left
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x1F
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0xFD # 0xFD for right instead of 0xFE like on left
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x21
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01 # 0x01 for right instead of 0x00 like on left
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x10
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3D
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x05
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3F
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x03
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x50
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x2C
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x76
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0E
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x7C
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x4A
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x81
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x03
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0x99
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x03
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xA4
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0xB5
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xA5
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xBA
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x94
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

  ## Windows driver sets 0x89 to 0 after initializing the speaker but it seems like the value is already 0 and the speaker seems to work anyway without seting this here?
  ## But *just in case* and especially with other devices, set 0x89 to 0 again here to be sure...
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x89
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00

    echo "Init back left speaker (0x3C)"

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3C

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

  ## Disable the speaker

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xFF
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3A
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x80
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

  ## Init

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xE1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x12
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x6F
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x14
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x1B
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x1D
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x1F
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0xFE
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x21
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x10
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3D
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x05
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3F
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x03
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x50
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x2C
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x76
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0E
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x7C
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x4A
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x81
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x03
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xBA
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x8D
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

  ## Windows driver sets 0x89 to 0 after initializing the speaker but it seems like the value is already 0 and the speaker seems to work anyway without seting this here?
  ## But *just in case* and especially with other devices, set 0x89 to 0 again here to be sure...
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x89
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00

    echo "Init back right speaker (0x3D)"

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3D

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

  ## Disable the speaker

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xFF
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3A
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x80
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

  ## Init

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xE1
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x12
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x6F
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x14
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x1B
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x02
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x1D
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x02
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x1F
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0xFD
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x21
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x10
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3D
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x05
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3F
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x03
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x50
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x2C
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x76
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x0E
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x7C
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x4A
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x81
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x03
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xBA
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x8D
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

  ## Windows driver sets 0x89 to 0 after initializing the speaker but it seems like the value is already 0 and the speaker seems to work anyway without seting this here?
  ## But *just in case* and especially with other devices, set 0x89 to 0 again here to be sure...
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x89
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00

    echo "Enable front left speaker (0x38)"

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x38

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3A
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x81
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xFF
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    echo "Enable front right speaker (0x39)"

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x39

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3A
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x81
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xFF
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    echo "Enable back left speaker (0x3C)"

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3C

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3A
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x81
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xFF
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    echo "Enable back right speaker (0x3D)"

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x22
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x3D

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x420 0x3A
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x81
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11

    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x23
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x423 0xFF
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x00
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x400 0x01
    ${pkgs.alsa-tools}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x4B0 0x11
  '';
in {
  environment.systemPackages = [pkgs.alsa-tools speakerSetupScript];

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

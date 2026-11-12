# Host tallyho: only selection and machine-specific values.
{ ... }: {
  flake.nixosModules.tallyhoConfiguration = {
    networking.hostName = "tallyho";

    # Recreate the working queue on each CUPS start, even with ephemeral state.
    # This printer's AirPrint/IPP connection fails; use native PostScript instead.
    hardware.printers = {
      ensurePrinters = [
        {
          name = "HP_LaserJet_Direct";
          description = "HP LaserJet M1536dnf (direct)";
          deviceUri = "socket://NPI90A41E.local:9100";
          model = "HP/hp-laserjet_m1530_mfp_series-ps.ppd.gz";
          ppdOptions."printer-is-shared" = "false";
        }
      ];
      ensureDefaultPrinter = "HP_LaserJet_Direct";
    };

    # Only for testing
    users.users.adrien.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDaoAxpR4xoz28qWydEXLeuBI1FlakwnYJyNnHjW62wG adrienmoreau@ik.me"
    ];

    system.stateVersion = "26.05";
  };
}

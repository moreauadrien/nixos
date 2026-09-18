# Host tallyho: only selection and machine-specific values.
{ ... }: {
  flake.nixosModules.tallyhoConfiguration = {
    networking.hostName = "tallyho";

    # Only for testing
    users.users.adrien.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDaoAxpR4xoz28qWydEXLeuBI1FlakwnYJyNnHjW62wG adrienmoreau@ik.me"
    ];

    system.stateVersion = "26.05";
  };
}

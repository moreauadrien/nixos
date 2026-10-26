{
  inputs,
  moduleWithSystem,
  ...
}: {
  perSystem = { inputs', ... }: {
    packages.pifzf = inputs'.pifzf.packages.pifzf;
  };

  flake.nixosModules.pifzf = moduleWithSystem ({ self', ... }: {
    hjem.users.adrien = {
      packages = [ self'.packages.pifzf ];
      files.".pi/agent/extensions/pifzf.ts".source = "${inputs.pifzf}/extension.ts";
    };
  });
}

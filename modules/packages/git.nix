{ inputs, ... }: {
  perSystem =
    { pkgs, ... }:
    {
      # Wrapped git: user identity + default branch baked into the wrapper via
      # GIT_CONFIG_GLOBAL (no env var exists for init.defaultBranch).
      # Do NOT put this in an overlay as `pkgs.git` (infinite recursion, the
      # wrapper builds git itself).
      packages.git = inputs.wrapper-modules.lib.wrapPackage [
        inputs.wrapper-modules.lib.wrapperModules.git
        {
          inherit pkgs;
          settings = {
            user = {
              name = "Adrien Moreau";
              email = "adrienmoreau@ik.me";
            };
            init.defaultBranch = "main";
          };
        }
      ];
    };
}

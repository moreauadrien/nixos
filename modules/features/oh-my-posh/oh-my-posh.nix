   {
     moduleWithSystem,
     inputs,
     ...
   }: {
     # Wrapped oh-my-posh: config.toml becomes the default --config for the binary.
     perSystem = { pkgs, ... }: {
       packages.oh-my-posh = inputs.wrapper-modules.lib.wrapPackage [
         inputs.wrapper-modules.lib.wrapperModules.oh-my-posh
         {
           inherit pkgs;
           configFile = ./config.toml;
         }
       ];
     };

     flake.nixosModules.oh-my-posh = moduleWithSystem ({ self', ... }: {
       hjem.users.adrien = {
         packages = [ self'.packages.oh-my-posh ];
         files.".bashrc".text = ''
           eval "$(oh-my-posh init bash)"
         '';
       };
     });
   }

   {
     moduleWithSystem,
     inputs,
     ...
   }: {
     flake.nixosModules.shell = moduleWithSystem ({ self', pkgs, ... }: {
       programs.zsh.enable = true;
       users.defaultUserShell = pkgs.zsh;

       hjem.users.adrien = {
         packages = [ 
           self'.packages.oh-my-posh
	   pkgs.wl-clipboard
	   pkgs.fzf
	 ];

	 files.".zshrc".text = ''
 eval "$(oh-my-posh init zsh)"

 bindkey -e

 setopt HIST_IGNORE_SPACE # use a space to hide a command from history
 source ${pkgs.fzf}/share/fzf/key-bindings.zsh
 for f in ~/.zshrc.d/*.zsh(N); do source "$f"; done
	'';

	 files.".zshrc.d/aliases.zsh".text = ''
	   compress() { tar -czf "''${1%/}.tar.gz" "''${1%/}"; }
	   alias decompress="tar -xzf"

	   # NixOS rebuild helpers (main checkout, host tallyho)
	   alias nrs="sudo nixos-rebuild switch --flake /home/adrien/nixos/main#tallyho"
	   alias nrt="sudo nixos-rebuild test --flake /home/adrien/nixos/main#tallyho"
	 '';
       };
     });

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
   }

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
	   ZVM_SYSTEM_CLIPBOARD_ENABLED=true
           # Ctrl-C quitte le mode insertion -> mode normal (à la place de Échap)
           ZVM_VI_INSERT_ESCAPE_BINDKEY='^C'

	   precmd()  { stty intr undef }   # avant l'affichage du prompt
	   preexec() { stty intr ^C }      # juste avant l'exécution d'une commande

           function zvm_after_init() {
             source ${pkgs.fzf}/share/fzf/key-bindings.zsh

             # Échap annule la commande en cours (ancien comportement de Ctrl-C)
             bindkey -M viins '^[' send-break

             # Snippets dropped by other modules (e.g. ts-sessionizer).
             # Must run inside zvm_after_init: zsh-vi-mode binds its keys late
             # (at the first precmd) and would otherwise clobber theirs.
             for f in ~/.zshrc.d/*.zsh(N); do source "$f"; done
           }

           source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
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

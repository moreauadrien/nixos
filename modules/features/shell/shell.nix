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

	   # tconf: tmux session in ~/nixos — pi on the left, touffu top-right,
	   # plain shell bottom-right. Reattaches if the session already exists.
	   tconf() {
	     local s=tconf
	     if tmux has-session -t "$s" 2>/dev/null; then
	       exec tmux attach -t "$s"
	     fi
	     tmux new-session -d -s "$s" -n work -c ~/nixos
	     tmux split-window -h -t "$s:work.1" -c ~/nixos -p 50
	     tmux split-window -v -t "$s:work.2" -c ~/nixos
	     tmux send-keys -t "$s:work.1" 'pi' C-m
	     tmux send-keys -t "$s:work.2" 'touffu' C-m
	     exec tmux attach -t "$s"
	   }
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

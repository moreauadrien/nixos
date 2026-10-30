# Neovim editor: binary, companion tools and the config from ./config.
{
  flake.nixosModules.neovim = { config, lib, pkgs, ... }: {
    programs.neovim = {
      enable = true;
      vimAlias = true;
      defaultEditor = true;
    };


    environment.systemPackages = with pkgs; [
      # Keep nvim.desktop's identity and MIME types, but bypass GLib's terminal
      # lookup by launching Foot directly. Higher priority replaces only the
      # wrapper's desktop entry, not Neovim itself.
      (lib.hiPrio (runCommand "neovim-desktop" {} ''
        mkdir -p $out/share/applications
        substitute ${config.programs.neovim.finalPackage}/share/applications/nvim.desktop \
          $out/share/applications/nvim.desktop \
          --replace-fail 'Exec=nvim %F' 'Exec=${foot}/bin/foot -e ${config.programs.neovim.finalPackage}/bin/nvim -- %F' \
          --replace-fail 'Terminal=true' 'Terminal=false'
      ''))
      git
      gnumake
      unzip
      gcc
      ripgrep
      fd
      tree-sitter

      # LSP (installed from nixpkgs: Mason-downloaded binaries are dynamically
      # linked generic-Linux executables and cannot run on NixOS)
      kdePackages.qtdeclarative # qmlls
      lua-language-server # lua_ls
      stylua # stylua --lsp (Lua formatting)
      rust-analyzer # rust_analyzer
      rustfmt # Rust formatting (conform.nvim)
      nixfmt # Nix formatting (conform.nvim)
      typstyle # Typst formatting (conform.nvim)
    ];





    # Link every file of ./config individually instead of the directory as a
    # whole: `vim.pack` (Nix 0.12+) writes its lockfile next to the config
    # ($XDG_CONFIG_HOME/nvim/nvim-pack-lock.json), which fails with EROFS when
    # ~/.config/nvim itself is a read-only store symlink. Individual file
    # links keep ~/.config/nvim a real, writable directory while the config
    # content stays managed in the store.
    hjem.users.adrien.files =
      let
        # All files under ./config, as "relative path" -> store path.
        configFiles = lib.listToAttrs (let
          go = dir: rel:
            lib.concatLists
              (lib.mapAttrsToList
                (name: type:
                  if type == "directory"
                  then go (dir + "/${name}") "${rel}/${name}"
                  else [ (lib.nameValuePair (lib.removePrefix "/" "${rel}/${name}") (dir + "/${name}")) ]
                )
                (builtins.readDir dir)
              );
        in
          go ./config "");
      in
        lib.listToAttrs (lib.mapAttrsToList
          (rel: source: lib.nameValuePair ".config/nvim/${rel}" { inherit source; })
          configFiles);
  };
}

# Neovim editor: binary, companion tools and the config from ./config.
{
  flake.nixosModules.neovim = { lib, ... }: {
    programs.neovim = {
      enable = true;
      vimAlias = true;
      defaultEditor = true;
    };

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

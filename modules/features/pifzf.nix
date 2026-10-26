{
  inputs,
  moduleWithSystem,
  ...
}: {
  perSystem = { inputs', ... }: {
    packages.pifzf = inputs'.pifzf.packages.pifzf.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace src/main.rs \
          --replace-fail 'a == b.trim() && a.starts_with("/dev/pts/")' \
                         'a.starts_with("/dev/pts/") && (a == b.trim() || env::var_os("PIFZF_POPUP").is_some())'
        sed -i '/println!("No interactive Pi sessions found in tmux.");/{N; s@println!("No interactive Pi sessions found in tmux.");\n *return Ok(());@return Err("No interactive Pi sessions found in tmux.".into());@;}' src/main.rs
        grep -q 'return Err("No interactive Pi sessions found in tmux.".into());' src/main.rs
      '';
    });
  };

  flake.nixosModules.pifzf = moduleWithSystem ({ self', ... }: {
    hjem.users.adrien = {
      packages = [ self'.packages.pifzf ];
      files.".pi/agent/extensions/pifzf.ts".source = "${inputs.pifzf}/extension.ts";
    };
  });
}

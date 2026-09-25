# cht.sh: the official cheat.sh client script (fetched from
# https://cht.sh/:cht.sh), wrapped so `curl` is on its PATH.
{ moduleWithSystem, ... }: {
  perSystem = { pkgs, ... }: {
    packages.cht-sh = pkgs.runCommand "cht-sh" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
      src = pkgs.fetchurl {
        url = "https://cht.sh/:cht.sh";
        hash = "sha256-0xNeQrgA/y56rETU3+UA8PTix+sAocIZGw3IsoQx8VU=";
      };
    } ''
      install -Dm755 $src $out/bin/cht.sh
      patchShebangs $out/bin/cht.sh
      wrapProgram $out/bin/cht.sh \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.curl ]}
    '';
  };

  flake.nixosModules.cht-sh = moduleWithSystem ({ self', ... }: {
    hjem.users.adrien.packages = [ self'.packages.cht-sh ];
  });
}

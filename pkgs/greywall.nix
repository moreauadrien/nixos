{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchurl,
  unzip,
  stdenv,
}: let
  version = "0.3.7";
  tun2socks-amd64 = fetchurl {
    url = "https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-linux-amd64.zip";
    hash = "sha256-SqdzcAmp8GufSVfE/BKTKuDNIDlHHSrk5dRmb/60Ci4=";
  };
  tun2socks-arm64 = fetchurl {
    url = "https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-linux-arm64.zip";
    hash = "sha256-uDvElhszqj7AOZyAGpfCxHdmRimR/6SIpMuu4as+C/8=";
  };
in
  buildGoModule {
    pname = "greywall";
    inherit version;
    src = fetchFromGitHub {
      owner = "GreyhavenHQ";
      repo = "greywall";
      rev = "v${version}";
      hash = "sha256-8wcROYE+c03u/j5xRaClgBCxF3VWlsazMCvCjmpjBHg=";
    };
    vendorHash = "sha256-HT5Dl79B0XoVLEbTIRsnQHYQxKlIXgxy0C78WD5a/V0=";
    nativeBuildInputs = [unzip];
    preBuild = ''
      mkdir -p internal/sandbox/bin
      ${unzip}/bin/unzip -o ${tun2socks-amd64} -d internal/sandbox/bin/
      ${unzip}/bin/unzip -o ${tun2socks-arm64} -d internal/sandbox/bin/
      chmod +x internal/sandbox/bin/tun2socks-linux-*
    '';
    ldflags = [
      "-s"
      "-w"
    ];
    subPackages = ["cmd/greywall"];
    env.CGO_ENABLED = "0";
    postInstall = ''
      ln -s $out/bin/greywall $out/bin/greywatch
    '';
    doCheck = false;
    meta = with lib; {
      description = "Container-free, deny-by-default sandbox for AI coding agents";
      homepage = "https://github.com/GreyhavenHQ/greywall";
      license = licenses.asl20;
      mainProgram = "greywall";
      platforms = platforms.linux ++ platforms.darwin;
      maintainers = [];
    };
  }

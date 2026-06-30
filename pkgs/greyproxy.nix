{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "greyproxy";
  version = "0.4.5";

  src = fetchFromGitHub {
    owner = "GreyhavenHQ";
    repo = "greyproxy";
    rev = "v${version}";
    hash = "sha256-d45vwS6YxmLCDtGFiOC0xfSsRV0KxU8jsxdgugBsWOE=";
  };

  vendorHash = "sha256-R6E5T8gYIFd87PgdKDFoE1w/Dhmb6or/mMH0Y48XoLA=";

  subPackages = [ "cmd/greyproxy" ];

  ldflags = [
    "-s"
    "-w"
  ];

  env.CGO_ENABLED = "0";

  doCheck = false;

  meta = with lib; {
    description = "SOCKS5 and DNS proxy with web dashboard for greywall network sandboxing";
    homepage = "https://github.com/GreyhavenHQ/greyproxy";
    license = licenses.mit;
    mainProgram = "greyproxy";
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = [ ];
  };
}

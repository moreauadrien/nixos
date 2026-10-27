#!/bin/sh
# Provision Nix (single-user) + devenv into the Alpine rootfs.
#
# Run by `gondolin build` via postBuild, chrooted and as root, in a single
# shell: the temporary mounts set up below are cleaned up by the EXIT trap.
set -eu

# The official installer creates /nix via sudo, which the rootfs does not
# ship: create it first so the installer skips that step.
mkdir -m 0755 /nix /etc/nix

# Single-user install: this rootfs has no nixbld group.
cat > /etc/nix/nix.conf <<'EOF'
build-users-group =
experimental-features = nix-command flakes
EOF

# The /dev bind that gondolin mounts into the chroot does not include /dev/pts
# (non-recursive bind): /dev/ptmx then points nowhere and nix cannot allocate
# a pty for its builds. Mount a private devpts instance on that bind (invisible
# from the build container), unmounted when this script exits.
mount -t devpts -o newinstance,ptmxmode=0666 devpts /dev/pts
trap 'umount /dev/pts' EXIT

curl -sSL https://nixos.org/nix/install | sh -s -- --no-daemon --yes --no-channel-add

# The Gondolin init mounts a tmpfs over /root at boot (ephemeral home): the
# single-user Nix profile would be invisible there. Expose it via
# /opt/nix-profile, outside the tmpfs. The target is the live profile symlink,
# not its resolution: every `nix profile install` creates a new generation
# behind that symlink.
ln -sfn /nix/var/nix/profiles/per-user/root/profile /opt/nix-profile

cat > /etc/profile.d/nix.sh <<'EOF'
export PATH="/opt/nix-profile/bin:$PATH"
export NIX_SSL_CERTFILE=/etc/ssl/certs/ca-certificates.crt
EOF

# Toolchain from Nix, not apk: GNU userland, networking, dev tools and shells
# an AI agent expects (plus the usual runtimes). nodejs ships npm in nixpkgs.
PATH=/opt/nix-profile/bin:$PATH nix profile install \
  nixpkgs#bash \
  nixpkgs#bzip2 \
  nixpkgs#coreutils \
  nixpkgs#curl \
  nixpkgs#devenv \
  nixpkgs#direnv \
  nixpkgs#fd \
  nixpkgs#findutils \
  nixpkgs#gawk \
  nixpkgs#git \
  nixpkgs#gnugrep \
  nixpkgs#gnused \
  nixpkgs#gnutar \
  nixpkgs#gzip \
  nixpkgs#jq \
  nixpkgs#less \
  nixpkgs#nodejs \
  nixpkgs#openssh \
  nixpkgs#procps \
  nixpkgs#python3 \
  nixpkgs#ripgrep \
  nixpkgs#unzip \
  nixpkgs#util-linux \
  nixpkgs#uv \
  nixpkgs#wget \
  nixpkgs#xz \
  nixpkgs#zip \
  nixpkgs#zstd \
  nixpkgs#tmux \
  nixpkgs#ungoogled-chromium

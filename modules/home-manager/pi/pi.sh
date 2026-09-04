set -euo pipefail

# Sandboxed pi coding agent.
#
# Runs pi in a rootless podman container with only the current directory
# and ~/.pi (auth/config) visible. The nix store lives in the persistent
# `pi-nix-store` volume (overlaid on top of the image's /nix), so packages
# fetched by nix/devenv from the binary caches are kept across runs.
#
# Usage:
#   pi [args...]   run pi in the current directory
#   pi shell       open a bash shell inside the container (debugging)
#   pi --rebuild   rebuild the image (pulls fresh base image + latest pi)

CONTEXT="$HOME/.config/pi-agent"
IMAGE="localhost/pi-agent:$(sha256sum "$CONTEXT/Containerfile" | cut -c1-12)"
VOLUME="pi-nix-store"

build() {
  echo "pi: building image $IMAGE" >&2
  podman build --pull=always --tag "$IMAGE" "$CONTEXT" >&2
}

if [ "${1:-}" = "--rebuild" ]; then
  shift
  build
elif ! podman image exists "$IMAGE"; then
  build
fi

mkdir -p "$HOME/.pi"

extra_args=()
if [ "${1:-}" = "shell" ]; then
  shift
  extra_args+=(--entrypoint /bin/bash)
fi

# Root inside the container maps to the calling user outside (rootless
# podman default), so files created in the bind mounts stay owned by you.
exec podman run --rm --interactive --tty \
  --security-opt no-new-privileges \
  --cap-drop ALL \
  --volume "$VOLUME:/nix:O" \
  --volume "$PWD:/workspace" \
  --workdir /workspace \
  --volume "$HOME/.pi:/root/.pi" \
  "${extra_args[@]}" \
  "$IMAGE" "$@"

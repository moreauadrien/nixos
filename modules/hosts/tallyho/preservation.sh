#!/usr/bin/env bash
# preservation — manage files and directories preserved at /persistent.
# Placeholders (@jq@, @findmnt@, @persist@, @repo@) are substituted at build time.

set -euo pipefail

readonly JQ="@jq@"
readonly FINDMNT="@findmnt@"
readonly PERSIST="@persist@"
readonly REPO="${PRESERVATION_REPO:-@repo@}"
readonly EXTRA="$REPO/modules/hosts/tallyho/preservation-extra.json"
readonly MANIFEST="/etc/preservation.json"

die() { printf 'preservation: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
preservation — manage preserved (persistent) paths

Usage:
  preservation ls           list preserved paths (system and user sections)
  preservation add <path>   preserve a file or directory

`add` copies the existing content of the path (currently living in the
temporary filesystem) to /persistent right away and bind-mounts it in
place, then records it in preservation-extra.json (inside the config
repo) and runs `sudo nixos-rebuild switch --flake .#tallyho`.
EOF
}

cmd_ls() {
  [ -f "$MANIFEST" ] || die "manifest $MANIFEST not found (is the module enabled?)"
  exec "$JQ" -r '
    "Système :",
    ((.system.directories // [])[] | "  d  \(.)"),
    ((.system.files // [])[] | "  f  \(.)"),
    "",
    (.users // {} | to_entries[] |
      "\(.key) (\(.value.home)) :",
      ((.value.directories // [])[] | "  d  \(.)"),
      ((.value.files // [])[] | "  f  \(.)"),
      "")
  ' "$MANIFEST"
}

is_persistent_mount() {
  # $1 = path; success if it is a mountpoint sourced from the persistent root
  local src
  src="$("$FINDMNT" -rno SOURCE --target "$1" 2>/dev/null || true)"
  [ -n "$src" ] || return 1
  case "$src" in
    "$PERSIST"|"$PERSIST"/*) return 0 ;;
    *) return 1 ;;
  esac
}

cmd_add() {
  local target="${1:-}"
  [ -n "$target" ] || die "add: missing <path>"

  # Resolve to a canonical absolute path (allowing not-yet-existing paths).
  target="$(realpath -m "$target")"

  case "$target" in
    "$PERSIST"|"$PERSIST"/*) die "refusing to add a path already on persistent storage: $target" ;;
    /nix/store/*|/nix/var/*) die "refusing to add a nix store path: $target" ;;
  esac

  local kind
  if [ -d "$target" ] && [ ! -L "$target" ]; then
    kind="directories"
  elif [ -f "$target" ] && [ ! -L "$target" ]; then
    kind="files"
  else
    # Missing path or symlink: treat as a directory and create it.
    kind="directories"
    sudo mkdir -p "$target"
    printf 'created missing directory: %s\n' "$target"
  fi

  # Map the path to an owning user (longest matching home directory).
  local user="" rel="" best=""
  while IFS=: read -r uname _ _ _ _ home _; do
    case "$target" in
      "$home"/*)
        if [ "${#home}" -gt "${#best}" ]; then
          best="$home"; user="$uname"; rel="${target#"$home"/}"
        fi
        ;;
    esac
  done < /etc/passwd

  # Already preserved? (e.g. declared statically in the Nix configuration)
  if is_persistent_mount "$target"; then
    printf 'already preserved: %s\n' "$target"
    return 0
  fi

  local pdest="$PERSIST$target"

  if [ ! -e "$pdest" ]; then
    if [ -e "$target" ]; then
      # The path exists in the temporary filesystem: save it right now,
      # otherwise its content would be lost on the next reboot.
      sudo mkdir -p "$(dirname "$pdest")"
      sudo cp -a "$target" "$pdest"
      printf 'saved existing content: %s -> %s\n' "$target" "$pdest"
    else
      sudo mkdir -p "$pdest"
      printf 'created persistent directory: %s\n' "$pdest"
    fi
  else
    printf 'persistent copy already exists: %s (kept as is)\n' "$pdest"
  fi

  # Bind-mount immediately so it is effective without waiting for a reboot.
  if [ -e "$target" ] && [ "$(stat -c %d:%i "$target")" != "$(stat -c %d:%i "$pdest")" ]; then
    sudo mount --bind "$pdest" "$target"
    printf 'bind-mounted %s -> %s\n' "$pdest" "$target"
  fi

  # Record the path in the declarative state file consumed by the module.
  if [ ! -f "$EXTRA" ]; then
    printf '{"system":{"directories":[],"files":[]},"users":{}}\n' | sudo tee "$EXTRA" > /dev/null
  fi
  local tmp
  tmp="$(mktemp)"
  "$JQ" --arg k "$kind" --arg p "$target" --arg u "$user" --arg r "$rel" \
    'if $u == "" then
       .system[$k] = (((.system[$k] // []) + [$p]) | unique)
     else
       .users[$u] = ((.users[$u] // {}) + {($k): (((.users[$u][$k] // []) + [$r]) | unique)})
     end' \
    "$EXTRA" > "$tmp.new"
  # Write as the invoking user when possible, so the state file stays
  # user-owned when the config repo lives in the user's home.
  if [ -w "$(dirname "$EXTRA")" ] && { [ ! -e "$EXTRA" ] || [ -w "$EXTRA" ]; }; then
    cp "$tmp.new" "$EXTRA"
    # When invoked via sudo, keep the state file owned by the real user.
    if [ -n "${SUDO_USER:-}" ] && [ "$(id -u)" -eq 0 ]; then
      chown "$SUDO_USER": "$EXTRA"
    fi
  else
    sudo install -m 0644 "$tmp.new" "$EXTRA"
  fi
  rm -f "$tmp.new"

  printf '\nAdded %s [%s]%s\n' "$target" "$kind" "${user:+ (user: $user)}"

  # Rebuild right away so the corresponding mount units become permanent.
  printf 'Running "sudo nixos-rebuild switch --flake .#tallyho"...\n'
  if ! (cd "$REPO" && sudo nixos-rebuild switch --flake .#tallyho); then
    die "rebuild failed; run 'sudo nixos-rebuild switch --flake .#tallyho' manually"
  fi
}

case "${1:-}" in
  ls) shift; cmd_ls "$@" ;;
  add) shift; cmd_add "$@" ;;
  -h|--help|help|"") usage ;;
  *) usage >&2; die "unknown command: $1" ;;
esac
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
  preservation ls              list preserved paths (system and user sections)
  preservation add <path>      preserve a file or directory
  preservation remove <path>   stop preserving a file or directory

`add` copies the existing content of the path (currently living in the
temporary filesystem) to /persistent right away and bind-mounts it in
place, then records it in preservation-extra.json (inside the config
repo) and runs `sudo nixos-rebuild switch --flake .#tallyho`.

`remove` undoes this: it unmounts the bind mount, moves the content back
to the temporary filesystem, deletes the copy from /persistent, drops
the path from preservation-extra.json and rebuilds. Paths declared
statically in the Nix configuration cannot be removed this way.
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
  # $1 = path; success if it is a mountpoint backed by the persistent root.
  # On btrfs, findmnt reports the source as "DEVICE[/subvol/path]", so a
  # plain source-prefix check is unreliable. Instead require the path to be
  # mounted (possibly through an ancestor) and to share its inode with the
  # persistent copy — bind mounts do.
  [ -e "$1" ] || return 1
  "$FINDMNT" --target "$1" > /dev/null 2>&1 || return 1
  local pdest="$PERSIST$1"
  [ -e "$pdest" ] || return 1
  [ "$(stat -c %d:%i "$1")" = "$(stat -c %d:%i "$pdest")" ]
}

in_manifest() {
  # $1 = path, $2 = user, $3 = path relative to the user's home; success if
  # the path is listed in the rendered manifest (/etc/preservation.json),
  # i.e. preserved declaratively rather than via preservation-extra.json.
  [ -f "$MANIFEST" ] || return 1
  "$JQ" -e --arg p "$1" --arg u "$2" --arg r "$3" '
    if $u == "" then
      ((.system.directories // []) | index($p)) or ((.system.files // []) | index($p))
    else
      ((.users[$u].directories // []) | index($r)) or ((.users[$u].files // []) | index($r))
    end' "$MANIFEST" > /dev/null
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

cmd_remove() {
  local target="${1:-}"
  [ -n "$target" ] || die "remove: missing <path>"

  # Resolve to a canonical absolute path (allowing not-yet-existing paths).
  target="$(realpath -m "$target")"

  case "$target" in
    "$PERSIST"|"$PERSIST"/*) die "refusing to remove a path on persistent storage: $target" ;;
    /nix/store/*|/nix/var/*) die "refusing to remove a nix store path: $target" ;;
  esac

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

  # Look the path up in the declarative state file.
  local extra_kind=""
  if [ -f "$EXTRA" ]; then
    extra_kind="$($JQ -r --arg p "$target" --arg u "$user" --arg r "$rel" '
      if $u == "" then
        if ((.system.files // []) | index($p)) then "files"
        elif ((.system.directories // []) | index($p)) then "directories"
        else "" end
      else
        if ((.users[$u].files // []) | index($r)) then "files"
        elif ((.users[$u].directories // []) | index($r)) then "directories"
        else "" end
      end' "$EXTRA")"
  fi
  if [ -z "$extra_kind" ]; then
    if in_manifest "$target" "$user" "$rel"; then
      die "$target is preserved, but statically declared in the Nix configuration (not in $EXTRA); edit modules/hosts/tallyho/preservation.nix to remove it, then rebuild"
    fi
    if is_persistent_mount "$target"; then
      die "$target is preserved but not recorded in $EXTRA; edit modules/hosts/tallyho/preservation.nix to remove it"
    fi
    local mnt
    mnt="$($FINDMNT -rno TARGET --target "$target" 2>/dev/null || true)"
    if [ -n "$mnt" ] && [ "$mnt" != "$target" ] && is_persistent_mount "$mnt"; then
      die "the path itself is not preserved, but it lives inside the preserved directory $mnt; run 'preservation remove $mnt' instead"
    fi
    die "not preserved: $target (see 'preservation ls')"
  fi

  # Unmount the bind mount if it is active.
  if is_persistent_mount "$target"; then
    if ! sudo umount "$target"; then
      die "could not unmount $target (busy?); close the programs using it and retry"
    fi
    printf 'unmounted %s\n' "$target"
  fi

  # Move the content back to the temporary filesystem and delete it from
  # persistent storage, so the path becomes ephemeral again.
  local pdest="$PERSIST$target"
  if [ -e "$pdest" ]; then
    if [ -e "$target" ]; then
      sudo rm -rf -- "$target"
    fi
    sudo mkdir -p -- "$(dirname "$target")"
    sudo mv -- "$pdest" "$target"
    printf 'moved %s back to the temporary filesystem: %s\n' "$pdest" "$target"
  else
    printf 'warning: no persistent copy at %s\n' "$pdest"
  fi

  # Clean up parent directories left empty under the persistent root.
  local parent="$(dirname "$pdest")"
  while [ "$parent" != "$PERSIST" ] && [ -d "$parent" ] && [ -z "$(ls -A "$parent" 2>/dev/null)" ]; do
    if ! sudo rmdir "$parent" 2>/dev/null; then
      break
    fi
    parent="$(dirname "$parent")"
  done

  # Drop the path from the declarative state file consumed by the module.
  local tmp
  tmp="$(mktemp)"
  $JQ --arg k "$extra_kind" --arg p "$target" --arg u "$user" --arg r "$rel" '
    if $u == "" then
      .system[$k] = ((.system[$k] // []) | map(select(. != $p)))
    else
      .users[$u][$k] = ((.users[$u][$k] // []) | map(select(. != $r)))
      | if ((.users[$u].directories // []) == [] and (.users[$u].files // []) == [])
        then del(.users[$u]) else . end
    end' "$EXTRA" > "$tmp.new"
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

  printf '\nRemoved %s [%s]%s\n' "$target" "$extra_kind" "${user:+ (user: $user)}"

  # Rebuild right away so the corresponding mount units are dropped.
  printf 'Running "sudo nixos-rebuild switch --flake .#tallyho"...\n'
  if ! (cd "$REPO" && sudo nixos-rebuild switch --flake .#tallyho); then
    die "rebuild failed; run 'sudo nixos-rebuild switch --flake .#tallyho' manually"
  fi
}

case "${1:-}" in
  ls) shift; cmd_ls "$@" ;;
  add) shift; cmd_add "$@" ;;
  remove|rm) shift; cmd_remove "$@" ;;
  -h|--help|help|"") usage ;;
  *) usage >&2; die "unknown command: $1" ;;
esac
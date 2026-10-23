#!/usr/bin/env bash
# Run with: bash modules/features/shell/test-tconf.sh
set -euo pipefail

source_file="$(dirname "$0")/shell.nix"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Exercise the actual function, with Nix's escaped interpolation unescaped.
sed -n '/^[[:space:]]*tconf() {/,/^[[:space:]]*}/p' "$source_file" \
  | sed "s/''//g" > "$tmp/function.sh"
cat > "$tmp/tmux" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$LOG"
if [[ $1 == has-session ]]; then
  exit "$MISSING"
fi
EOF
chmod +x "$tmp/tmux"

for missing in 0 1; do
  for inside in '' test-server; do
    export LOG="$tmp/log" MISSING="$missing"
    : > "$LOG"
    PATH="$tmp:$PATH" TMUX="$inside" bash -c \
      'source "$1"; tconf; echo shell-survived >> "$LOG"' _ "$tmp/function.sh"
    if [[ -n $inside ]]; then
      grep -qx 'switch-client -t tconf' "$LOG"
      grep -qx 'shell-survived' "$LOG"
      ! grep -q '^attach ' "$LOG"
    else
      grep -qx 'attach -t tconf' "$LOG"
      ! grep -q '^switch-client\|shell-survived' "$LOG"
    fi
    [[ $(grep -c '^new-session ' "$LOG") -eq $missing ]]
    [[ $(grep -c '^split-window ' "$LOG") -eq $((missing * 2)) ]]
    [[ $(grep -c '^send-keys ' "$LOG") -eq $((missing * 2)) ]]
  done
done
printf 'tconf: all four create/reuse and switch/attach cases passed\n'

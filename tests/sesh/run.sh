#!/usr/bin/env bash
# Run with: bash tests/sesh/run.sh (requires Nix).
set -euo pipefail
cd "$(dirname "$0")/../.."
package=$(nix --extra-experimental-features 'nix-command flakes' build .#sesh-picker --no-link --print-out-paths)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Keep the built script, replacing only the dependency PATH for command mocks.
sed '/^export PATH=/d' "$package/bin/sesh-picker" > "$tmp/picker"
export PATH="$tmp:$PATH" TEST_LOG="$tmp/log"
cat > "$tmp/sesh" <<'MOCK'
#!/usr/bin/env bash
if [[ $1 == list ]]; then
  printf '%s\n' 'project with spaces'
else
  [[ $# == 2 && $1 == connect && $2 == 'project with spaces' ]] || exit 1
  echo connected >> "$TEST_LOG"
fi
MOCK
cat > "$tmp/fzf" <<'MOCK'
#!/usr/bin/env bash
echo "${0##*/}" >> "$TEST_LOG"
[[ " $* " == *' --ansi '* ]] || exit 1
cat >/dev/null
case ${TEST_MODE:-select} in
  select) printf '%s\n' 'project with spaces' ;;
  cancel) exit 130 ;;
  empty) exit 0 ;;
esac
MOCK
cp "$tmp/fzf" "$tmp/fzf-tmux"
chmod +x "$tmp/sesh" "$tmp/fzf" "$tmp/fzf-tmux"

for context in outside inside; do
  if [[ $context == inside ]]; then
    export TMUX=test
    expected=fzf-tmux
  else
    unset TMUX
    expected=fzf
  fi
  for mode in select cancel empty; do
    : > "$TEST_LOG"
    TEST_MODE=$mode bash "$tmp/picker"
    printf '%s\n' "$expected" > "$tmp/expected"
    if [[ $mode == select ]]; then
      echo connected >> "$tmp/expected"
    fi
    diff -u "$tmp/expected" "$TEST_LOG"
  done
done
echo 'PASS: sesh picker inside/outside tmux, selection, cancellation and empty result'

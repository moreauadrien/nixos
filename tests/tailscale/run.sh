#!/usr/bin/env bash
# Run with: bash tests/tailscale/run.sh (requires quickshell).
set -euo pipefail
cd "$(dirname "$0")"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export TAILSCALE_TEST_LOG="$tmp/commands"
export PATH="$tmp:$PATH"
: > "$TAILSCALE_TEST_LOG"
cat > "$tmp/tailscale" <<'MOCK'
#!/usr/bin/env bash
if [ "$*" = 'status --json' ]; then
    printf '%s\n' '{"BackendState":"Running","Self":{"ID":"self","HostName":"test","TailscaleIPs":["100.64.0.1"]},"Peer":{"a":{"ID":"online","DNSName":"exit.test.ts.net.","Online":true,"ExitNodeOption":true,"TailscaleIPs":["100.64.0.2"]},"b":{"ID":"offline","HostName":"offline","Online":false,"ExitNodeOption":true,"TailscaleIPs":["100.64.0.3"]},"c":{"ID":"ordinary","HostName":"ordinary","Online":false}}}'
else
    printf '%s\n' "$*" >> "$TAILSCALE_TEST_LOG"
    if [ "$1" = fail ]; then
        echo 'permission denied' >&2
        exit 1
    fi
fi
MOCK
chmod +x "$tmp/tailscale"
mkdir "$tmp/config"
cp -r ../../modules/features/quickshell/config/{components,services} "$tmp/config/"
cp shell.qml "$tmp/config/"
unset WAYLAND_DISPLAY
QT_QPA_PLATFORM=offscreen quickshell --no-color -p "$tmp/config/shell.qml" > "$tmp/output" 2>&1 || {
    tail -100 "$tmp/output"
    exit 1
}
tail -100 "$tmp/output"
grep -q 'PASS: Tailscale service and panel' "$tmp/output"
if grep -E 'FAIL:|ReferenceError:|TypeError:|Error:|Unable to assign' "$tmp/output"; then
    exit 1
fi
printf '%s\n' 'set --exit-node=100.64.0.2' 'set --exit-node=' down up fail > "$tmp/expected"
diff -u "$tmp/expected" "$TAILSCALE_TEST_LOG"

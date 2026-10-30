#!/usr/bin/env bash
# Run with: bash tests/network/run.sh (requires quickshell).
set -euo pipefail
cd "$(dirname "$0")"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export NETWORK_TEST_LOG="$tmp/commands"
export PATH="$tmp:$PATH"
: > "$NETWORK_TEST_LOG"
cat > "$tmp/network-control" <<'MOCK'
#!/usr/bin/env bash
case "$1" in
status)
    printf '%s\n' '{"available":true,"wifiEnabled":true,"devices":[{"interface":"eth0","type":"ethernet","uuid":"wired-uuid"},{"interface":"wlan0","type":"wifi","uuid":"wifi-uuid"}],"active":{"interface":"eth0","type":"ethernet","name":"Ethernet","uuid":"wired-uuid"},"networks":[{"ssid":"Other","bssid":"AA:BB:CC:DD:EE:00","signal":99,"security":"WPA2","active":false,"known":false,"interface":"wlan0"},{"ssid":"Home: wifi","bssid":"AA:BB:CC:DD:EE:FF","signal":50,"security":"WPA2","active":true,"known":true,"uuid":"wifi-uuid","interface":"wlan0"}]}'
    ;;
action)
    IFS= read -r request
    printf '%s\n' "$request" >> "$NETWORK_TEST_LOG"
    if [[ "$request" == *'"password":"wrong-secret"'* ]]; then
        sleep 0.2
        printf '%s\n' '{"ok":false,"error":"Connection failed"}'
        exit 1
    fi
    if [[ "$request" == *'"action":"fail"'* ]]; then
        printf '%s\n' '{"ok":false,"error":"Permission denied"}'
        exit 1
    fi
    printf '%s\n' '{"ok":true}'
    ;;
esac
MOCK
chmod +x "$tmp/network-control"
mkdir "$tmp/config"
cp -r ../../modules/features/quickshell/config/{components,services} "$tmp/config/"
cp shell.qml "$tmp/config/"
unset WAYLAND_DISPLAY
QT_QPA_PLATFORM=offscreen quickshell --no-color -p "$tmp/config/shell.qml" > "$tmp/output" 2>&1 || {
    tail -100 "$tmp/output"
    exit 1
}
tail -100 "$tmp/output"
grep -q 'PASS: Network service and panel' "$tmp/output"
if grep -E 'FAIL:|ReferenceError:|TypeError:|Error:|Unable to assign' "$tmp/output"; then exit 1; fi
[ "$(wc -l < "$NETWORK_TEST_LOG")" -eq 9 ]
! head -6 "$NETWORK_TEST_LOG" | tail -1 | grep -q '"password"'
grep -q '"password":"corrected-secret"' "$NETWORK_TEST_LOG"
grep -q '"action":"connect".*"password":"test-secret"' "$NETWORK_TEST_LOG"
grep -q '"action":"wired","interface":"eth0"' "$NETWORK_TEST_LOG"
grep -q '"action":"disconnect","interface":"wlan0"' "$NETWORK_TEST_LOG"
! grep -E 'test-secret|wrong-secret|corrected-secret' "$tmp/output"

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
    printf '%s\n' '{"available":true,"wifiEnabled":true,"devices":[{"interface":"eth0","type":"ethernet","uuid":"wired-uuid"},{"interface":"wlan0","type":"wifi","uuid":"wifi-uuid"}],"active":{"interface":"eth0","type":"ethernet","name":"Ethernet","uuid":"wired-uuid","ip":"192.0.2.2","gateway":"192.0.2.1","dns":["192.0.2.1"],"rxBytes":4096,"txBytes":2048},"networks":[{"ssid":"Other","bssid":"AA:BB:CC:DD:EE:00","signal":99,"security":"WPA2","active":false,"known":false,"interface":"wlan0"},{"ssid":"Home: wifi","bssid":"AA:BB:CC:DD:EE:FF","signal":50,"security":"WPA2","active":true,"known":true,"uuid":"wifi-uuid","interface":"wlan0"}]}'
    ;;
action)
    IFS= read -r request
    printf '%s\n' "$request" >> "$NETWORK_TEST_LOG"
    if [[ "$request" == *'"action":"fail"'* ]]; then
        printf '%s\n' '{"ok":false,"error":"Permission denied"}'
        exit 1
    fi
    printf '%s\n' '{"ok":true}'
    ;;
probe) printf '%s\n' '{"pingMs":12,"packetLoss":0}' ;;
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
[ "$(wc -l < "$NETWORK_TEST_LOG")" -eq 6 ]
! tail -1 "$NETWORK_TEST_LOG" | grep -q '"password"'
grep -q '"action":"connect".*"password":"test-secret"' "$NETWORK_TEST_LOG"
grep -q '"action":"dns","uuid":"wired-uuid"' "$NETWORK_TEST_LOG"
grep -q '"action":"band","uuid":"wifi-uuid"' "$NETWORK_TEST_LOG"
! grep -q 'test-secret' "$tmp/output"

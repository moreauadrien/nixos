# Network widget checks

```sh
nix shell nixpkgs#python3 --command python3 -B -m unittest discover -s tests/network -p 'test_*.py'
bash tests/network/run.sh
nix build .#network-control --no-link
```

Backend tests mock NetworkManager: no live connections or DNS settings change.
The QML test runs the real panel and service offscreen against a mock helper.
`nix run .#network-control -- status` is a read-only live smoke check.

The panel supports visible personal/open Wi-Fi networks and existing profiles.
Hidden SSID and enterprise identity/certificate provisioning are not included.
DNS changes persist in the selected default connection profile; VPN DNS can take
priority. Band changes reassociate Wi-Fi and can briefly interrupt traffic.
Traffic totals are kernel interface counters; latency/loss probes target 1.1.1.1
only while the panel is open. Wi-Fi passwords travel to the helper on stdin,
never in command-line arguments or temporary credential files.

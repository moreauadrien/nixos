# Network widget checks

```sh
nix shell nixpkgs#python3 --command python3 -B -m unittest discover -s tests/network -p 'test_*.py'
bash tests/network/run.sh
nix build .#network-control --no-link
```

Backend tests mock NetworkManager; no live connections change. The QML test
runs the panel and service offscreen against a mock helper.
`nix run .#network-control -- status` is a read-only live smoke check.

Only Wi-Fi and Ethernet are managed: toggle Wi-Fi, scan, connect, disconnect,
and forget saved Wi-Fi profiles. The `wired` action connects an Ethernet
interface. Both interfaces can remain connected; the default route determines
the active connection, with Ethernet preferred on a tie.

Visible personal/open Wi-Fi networks and existing profiles are supported;
hidden SSID and enterprise provisioning are not included. Passwords, including
saved-profile retries, travel only on stdin, never in arguments or files.

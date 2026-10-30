"""Small NetworkManager CLI adapter. All output is JSON; secrets only travel on stdin."""

import ipaddress
import json
import os
from pathlib import Path
import re
import subprocess
import sys


DNS_PRESETS = {
    "auto": "",
    "cloudflare": "1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001",
    "google": "8.8.8.8 8.8.4.4 2001:4860:4860::8888 2001:4860:4860::8844",
}


class NetworkError(Exception):
    pass


def run(args, *, input=None, timeout=25, check=True):
    try:
        result = subprocess.run(args, input=input, text=True, capture_output=True,
                                timeout=timeout, env={**os.environ, "LC_ALL": "C"})
    except (OSError, subprocess.TimeoutExpired):
        raise NetworkError("Network command unavailable or timed out") from None
    if check and result.returncode:
        # Never relay nmcli's stderr: it can contain credentials supplied by stdin.
        raise NetworkError("NetworkManager command failed (check connection and permissions)")
    return result


def nm(*args, **kwargs):
    return run(["nmcli", "--wait", "20", *args], **kwargs).stdout.rstrip("\n")


def split_row(line):
    """Split nmcli --terse --escape yes without damaging escaped SSIDs."""
    fields, field, escaped = [], [], False
    for char in line:
        if escaped:
            field.append(char)
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == ":":
            fields.append("".join(field))
            field = []
        else:
            field.append(char)
    if escaped:
        field.append("\\")
    return fields + ["".join(field)]


def rows(fields, *args):
    output = nm("--terse", "--escape", "yes", "--fields", fields, *args)
    return [split_row(line) for line in output.splitlines() if line]


def properties(fields, *args):
    result = {}
    for row in rows(fields, *args):
        key = re.sub(r"\[\d+\]$", "", row[0])
        result.setdefault(key, []).append(":".join(row[1:]))
    return result


def first(values, key, default=""):
    return next((v for v in values.get(key, []) if v and v != "--"), default)


def profiles():
    known = {}
    for uuid, kind in rows("UUID,TYPE", "connection", "show"):
        if kind in ("802-11-wireless", "wifi"):
            data = properties("802-11-wireless.ssid", "connection", "show", "uuid", uuid)
            ssid = first(data, "802-11-wireless.ssid")
            if ssid:
                known.setdefault(ssid, uuid)
    return known


def counter(interface, name):
    if not re.fullmatch(r"[A-Za-z0-9_.:-]+", interface):
        return 0
    try:
        return int(Path(f"/sys/class/net/{interface}/statistics/{name}_bytes").read_text())
    except (OSError, ValueError):
        return 0


def dns_mode(profile):
    servers = {str(ipaddress.ip_address(value))
               for key in ("ipv4.dns", "ipv6.dns") for field in profile.get(key, [])
               for value in re.split(r"[\s,;]+", field) if value and value != "--"}
    ignored = [first(profile, f"ipv{version}.ignore-auto-dns", "no") == "yes" for version in (4, 6)]
    if not any(ignored) and not servers:
        return "auto"
    if all(ignored):
        for mode in ("cloudflare", "google"):
            if servers == set(DNS_PRESETS[mode].split()):
                return mode
    return "custom"


def status():
    snapshot = {"available": False, "wifiEnabled": False, "wifiBand": "auto", "devices": [],
                "networks": [], "active": None}
    try:
        snapshot["wifiEnabled"] = nm("radio", "wifi") == "enabled"
        known = profiles()
        candidates = []
        for interface, kind, state, connection in rows("DEVICE,TYPE,STATE,CONNECTION", "device", "status"):
            data = properties("GENERAL.CON-UUID,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS,IP6.GATEWAY,IP6.DNS",
                              "device", "show", interface)
            uuid = first(data, "GENERAL.CON-UUID")
            snapshot["devices"].append({"interface": interface, "type": kind,
                                        "state": state, "connection": connection if connection != "--" else "",
                                        "uuid": uuid})
            if state != "connected" or not uuid:
                continue
            defaults = properties("GENERAL.DEFAULT,GENERAL.DEFAULT6,ipv4.ignore-auto-dns,ipv4.dns,ipv6.ignore-auto-dns,ipv6.dns",
                                  "connection", "show", "uuid", uuid)
            band = "auto"
            if kind == "wifi":
                band = first(properties("802-11-wireless.band", "connection", "show", "uuid", uuid),
                             "802-11-wireless.band", "auto")
                snapshot["wifiBand"] = band if band in ("bg", "a") else "auto"
            active = {"interface": interface, "type": kind, "name": connection, "uuid": uuid,
                      "ip": first(data, "IP4.ADDRESS", first(data, "IP6.ADDRESS")),
                      "gateway": first(data, "IP4.GATEWAY", first(data, "IP6.GATEWAY")),
                      "dns": [v for key in ("IP4.DNS", "IP6.DNS") for v in data.get(key, []) if v and v != "--"],
                      "band": band if band in ("bg", "a") else "auto", "dnsMode": dns_mode(defaults),
                      "rxBytes": counter(interface, "rx"), "txBytes": counter(interface, "tx")}
            default = any(first(defaults, key) == "yes" for key in ("GENERAL.DEFAULT", "GENERAL.DEFAULT6"))
            candidates.append(((default, kind == "ethernet"), active))
        if candidates:
            snapshot["active"] = max(candidates, key=lambda item: item[0])[1]
        for ssid, bssid, signal, security, frequency, active, interface in rows(
                "SSID,BSSID,SIGNAL,SECURITY,FREQ,IN-USE,DEVICE", "device", "wifi", "list", "--rescan", "no"):
            snapshot["networks"].append({"ssid": ssid, "bssid": bssid, "signal": int(signal or 0),
                                         "security": security if security != "--" else "",
                                         "frequency": int(frequency.split()[0]) if frequency else 0, "active": active == "*",
                                         "known": ssid in known, "uuid": known.get(ssid, ""), "interface": interface})
        snapshot["available"] = True
    except (NetworkError, ValueError) as error:
        snapshot["error"] = str(error) if isinstance(error, NetworkError) else "Invalid NetworkManager response"
    return snapshot


def required(request, key):
    value = request.get(key)
    if not isinstance(value, str) or not value or value.startswith("-") or any(c in value for c in "\n\r\x00"):
        raise NetworkError(f"Invalid {key}")
    return value


def apply(uuid):
    devices = rows("UUID,DEVICE", "connection", "show", "--active")
    for active_uuid, interface in devices:
        if active_uuid == uuid and interface and interface != "--":
            try:
                nm("device", "reapply", interface)
            except NetworkError:
                nm("connection", "up", "uuid", uuid, "ifname", interface)


def action(request):
    if not isinstance(request, dict):
        raise NetworkError("Expected a JSON object")
    name = request.get("action")
    if name == "wifi":
        if type(request.get("enabled")) is not bool:
            raise NetworkError("enabled must be boolean")
        nm("radio", "wifi", "on" if request["enabled"] else "off")
    elif name == "scan":
        args = ["device", "wifi", "rescan"]
        if request.get("interface"):
            args += ["ifname", required(request, "interface")]
        nm(*args)
    elif name == "connect":
        interface, bssid = required(request, "interface"), required(request, "bssid")
        if not re.fullmatch(r"(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}", bssid):
            raise NetworkError("Invalid bssid")
        password = request.get("password")
        if password is not None and (not isinstance(password, str) or any(c in password for c in "\n\r\x00")):
            raise NetworkError("Invalid password")
        uuid = request.get("uuid")
        if not uuid:
            # Resolve by the profile's SSID, not its user-editable connection name.
            known = profiles()
            for ssid, address in rows("SSID,BSSID", "device", "wifi", "list", "ifname", interface, "--rescan", "no"):
                if address.lower() == bssid.lower():
                    uuid = known.get(ssid)
                    break
        if uuid:
            args = ["connection", "up", "uuid", required({"uuid": uuid}, "uuid"), "ifname", interface, "ap", bssid]
            if password is not None:
                # nmcli passwd-file accepts setting.property:secret lines. /dev/stdin
                # is the subprocess pipe, never a credential file on disk.
                nm(*args, "passwd-file", "/dev/stdin", input="802-11-wireless-security.psk:" + password + "\n")
            else:
                nm(*args)
        else:
            nm("--ask", "device", "wifi", "connect", bssid, "ifname", interface,
               input=(password + "\n") if password is not None else "")
    elif name == "disconnect":
        nm("device", "disconnect", required(request, "interface"))
    elif name == "forget":
        nm("connection", "delete", "uuid", required(request, "uuid"))
    elif name == "dns":
        uuid = required(request, "uuid")
        mode = request.get("mode")
        if mode not in (*DNS_PRESETS, "custom"):
            raise NetworkError("Invalid DNS mode")
        servers = request.get("servers", "") if mode == "custom" else DNS_PRESETS[mode]
        if not isinstance(servers, str):
            raise NetworkError("Invalid DNS servers")
        try:
            addresses = [ipaddress.ip_address(value) for value in re.split(r"[\s,;]+", servers.strip()) if value]
        except ValueError:
            raise NetworkError("Invalid DNS address") from None
        if any(getattr(ip, "scope_id", None) for ip in addresses):
            raise NetworkError("Scoped DNS addresses are not supported")
        if mode == "custom" and not addresses:
            raise NetworkError("Custom DNS requires an address")
        args = ["connection", "modify", "uuid", uuid]
        for version in (4, 6):
            args += [f"ipv{version}.ignore-auto-dns", "no" if mode == "auto" else "yes",
                     f"ipv{version}.dns", ",".join(str(ip) for ip in addresses if ip.version == version)]
        nm(*args)
        apply(uuid)
    elif name == "band":
        uuid = required(request, "uuid")
        band = request.get("band")
        if band not in ("auto", "bg", "a"):
            raise NetworkError("Invalid Wi-Fi band")
        # Band selection needs a new association, not just device reapply.
        nm("connection", "modify", "uuid", uuid, "802-11-wireless.band", "" if band == "auto" else band)
        for active_uuid, interface in rows("UUID,DEVICE", "connection", "show", "--active"):
            if active_uuid == uuid:
                nm("connection", "up", "uuid", uuid, "ifname", interface)
    else:
        raise NetworkError("Unknown action")
    return {"ok": True}


def probe(interface=None):
    args = ["ping", "-n", "-c", "3", "-W", "2", "-w", "7"]
    if interface is not None:
        args += ["-I", required({"interface": interface}, "interface")]
    result = run([*args, "1.1.1.1"], timeout=9, check=False)
    loss = re.search(r"([\d.]+)% packet loss", result.stdout)
    timing = re.search(r"= [\d.]+/([\d.]+)/", result.stdout)
    return {"pingMs": float(timing[1]) if timing else None,
            "packetLoss": float(loss[1]) if loss else 100.0}


def main():
    command = sys.argv[1:]
    try:
        if command == ["status"]:
            result = status()
        elif command == ["action"]:
            result = action(json.load(sys.stdin))
        elif command and command[0] == "probe" and len(command) <= 2:
            result = probe(command[1] if len(command) == 2 else None)
        else:
            raise NetworkError("Usage: network-control status|action|probe [interface]")
    except (NetworkError, ValueError, TypeError):
        # Parse errors can embed arbitrary request text, including passwords.
        error = sys.exc_info()[1]
        print(json.dumps({"ok": False, "error": str(error) if isinstance(error, NetworkError) else "Invalid request"}))
        return 1
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())

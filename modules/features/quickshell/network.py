"""Small NetworkManager CLI adapter. All output is JSON; secrets only travel on stdin."""

import json
import os
import re
import subprocess
import sys


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


def status():
    snapshot = {"available": False, "wifiEnabled": False, "devices": [],
                "networks": [], "active": None}
    try:
        snapshot["wifiEnabled"] = nm("radio", "wifi") == "enabled"
        known = profiles()
        candidates = []
        for interface, kind, state, connection in rows("DEVICE,TYPE,STATE,CONNECTION", "device", "status"):
            if kind not in ("wifi", "ethernet"):
                continue
            data = properties("GENERAL.CON-UUID", "device", "show", interface)
            uuid = first(data, "GENERAL.CON-UUID")
            snapshot["devices"].append({"interface": interface, "type": kind,
                                        "state": state, "connection": connection if connection != "--" else "",
                                        "uuid": uuid})
            if state != "connected" or not uuid:
                continue
            defaults = properties("GENERAL.DEFAULT,GENERAL.DEFAULT6", "connection", "show", "uuid", uuid)
            active = {"interface": interface, "type": kind, "name": connection, "uuid": uuid}
            default = any(first(defaults, key) == "yes" for key in ("GENERAL.DEFAULT", "GENERAL.DEFAULT6"))
            candidates.append(((default, kind == "ethernet"), active))
        if candidates:
            snapshot["active"] = max(candidates, key=lambda item: item[0])[1]
        for ssid, bssid, signal, security, active, interface in rows(
                "SSID,BSSID,SIGNAL,SECURITY,IN-USE,DEVICE", "device", "wifi", "list", "--rescan", "no"):
            snapshot["networks"].append({"ssid": ssid, "bssid": bssid, "signal": int(signal or 0),
                                         "security": security if security != "--" else "",
                                         "active": active == "*",
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
    elif name == "wired":
        nm("device", "connect", required(request, "interface"))
    elif name == "disconnect":
        nm("device", "disconnect", required(request, "interface"))
    elif name == "forget":
        nm("connection", "delete", "uuid", required(request, "uuid"))
    else:
        raise NetworkError("Unknown action")
    return {"ok": True}


def main():
    command = sys.argv[1:]
    try:
        if command == ["status"]:
            result = status()
        elif command == ["action"]:
            result = action(json.load(sys.stdin))
        else:
            raise NetworkError("Usage: network-control status|action")
    except (NetworkError, ValueError, TypeError):
        # Parse errors can embed arbitrary request text, including passwords.
        error = sys.exc_info()[1]
        print(json.dumps({"ok": False, "error": str(error) if isinstance(error, NetworkError) else "Invalid request"}))
        return 1
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())

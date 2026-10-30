"""Run: python3 -m unittest discover -s tests/network -v"""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "network", Path(__file__).resolve().parents[2] / "modules/features/quickshell/network.py")
backend = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(backend)


def completed(stdout="", returncode=0, stderr=""):
    return subprocess.CompletedProcess([], returncode, stdout, stderr)


def escape(value):
    return value.replace("\\", "\\\\").replace(":", "\\:")


def line(*fields):
    return ":".join(escape(str(value)) for value in fields) + "\n"


class BackendTest(unittest.TestCase):
    def test_escaped_rows_and_spaces(self):
        self.assertEqual(backend.split_row(r" home\:office\\router :AA\:BB:80"),
                         [" home:office\\router ", "AA:BB", "80"])
        with patch.object(backend.subprocess, "run", return_value=completed(" space \\:name :x\n")):
            self.assertEqual(backend.rows("SSID", "device"), [[" space :name ", "x"]])

    def status_runner(self, *, wired_default=True, wifi_default=True):
        def respond(args, **kwargs):
            self.assertEqual(kwargs["env"]["LC_ALL"], "C")
            self.assertLessEqual(kwargs["timeout"], 25)
            command = args[3:]
            if command == ["radio", "wifi"]:
                return completed("enabled\n")
            fields = command[command.index("--fields") + 1]
            tail = command[command.index("--fields") + 2:]
            if fields == "UUID,TYPE":
                return completed(line("wifi-uuid", "802-11-wireless") + line("wired-uuid", "802-3-ethernet"))
            if fields == "802-11-wireless.ssid":
                return completed(line(fields, " café:home\\net "))
            if fields == "DEVICE,TYPE,STATE,CONNECTION":
                return completed(line("wlan0", "wifi", "connected", "Profile NOT SSID") +
                                 line("eth0", "ethernet", "connected", "Wired") +
                                 line("lo", "loopback", "disconnected", "--"))
            if fields == "GENERAL.CON-UUID":
                iface = tail[-1]
                self.assertIn(iface, ("eth0", "wlan0"))
                return completed(line("GENERAL.CON-UUID", "wired-uuid" if iface == "eth0" else "wifi-uuid"))
            if fields == "GENERAL.DEFAULT,GENERAL.DEFAULT6":
                default = wired_default if tail[-1] == "wired-uuid" else wifi_default
                return completed(line("GENERAL.DEFAULT", "yes" if default else "no") +
                                 line("GENERAL.DEFAULT6", "no"))
            if fields.startswith("SSID,BSSID,SIGNAL"):
                return completed(line(" café:home\\net ", "AA:BB:CC:DD:EE:FF", 81, "WPA2", "*", "wlan0"))
            self.fail(f"Unexpected nmcli call: {args}")
        return respond

    def test_wired_default_preferred_but_wifi_still_active(self):
        with patch.object(backend.subprocess, "run", side_effect=self.status_runner()):
            data = backend.status()
        self.assertTrue(data["available"], data)
        self.assertTrue(data["wifiEnabled"])
        self.assertEqual(data["active"]["interface"], "eth0")
        self.assertEqual(set(data), {"available", "wifiEnabled", "devices", "networks", "active"})
        self.assertEqual(data["active"], {"interface": "eth0", "type": "ethernet", "name": "Wired", "uuid": "wired-uuid"})
        self.assertEqual([device["interface"] for device in data["devices"]], ["wlan0", "eth0"])
        for device in data["devices"]:
            self.assertEqual(set(device), {"interface", "type", "state", "connection", "uuid"})
        wifi = data["networks"][0]
        self.assertEqual(wifi["ssid"], " café:home\\net ")
        self.assertEqual(wifi["uuid"], "wifi-uuid")
        self.assertEqual(set(wifi), {"ssid", "bssid", "signal", "security", "active", "known", "uuid", "interface"})
        self.assertTrue(wifi["known"] and wifi["active"])

    def test_wifi_default_beats_nondefault_wired(self):
        with patch.object(backend.subprocess, "run", side_effect=self.status_runner(wired_default=False)):
            data = backend.status()
        self.assertEqual(data["active"]["interface"], "wlan0")

    def test_unavailable_and_disconnected(self):
        with patch.object(backend.subprocess, "run", side_effect=FileNotFoundError):
            self.assertFalse(backend.status()["available"])
        with patch.object(backend.subprocess, "run", return_value=completed()):
            self.assertIsNone(backend.status()["active"])

    def test_password_only_on_stdin(self):
        secret = 'pass:$;"\\word'
        with patch.object(backend, "profiles", return_value={}), \
                patch.object(backend, "rows", return_value=[]), \
                patch.object(backend.subprocess, "run", return_value=completed()) as run:
            self.assertEqual(backend.action({"action": "connect", "interface": "wlan0",
                                            "bssid": "AA:BB:CC:DD:EE:FF", "password": secret}), {"ok": True})
        args, kwargs = run.call_args
        self.assertNotIn(secret, str(args))
        self.assertEqual(kwargs["input"], secret + "\n")
        self.assertIn("--ask", args[0])
        self.assertNotIn("shell", kwargs)

    def test_saved_profile_reused_by_ssid(self):
        with patch.object(backend, "profiles", return_value={"real ssid": "saved-uuid"}), \
                patch.object(backend, "rows", return_value=[["real ssid", "AA:BB:CC:DD:EE:FF"]]), \
                patch.object(backend, "nm") as nm:
            backend.action({"action": "connect", "interface": "wlan0", "bssid": "AA:BB:CC:DD:EE:FF"})
        nm.assert_called_once_with("connection", "up", "uuid", "saved-uuid", "ifname", "wlan0", "ap", "AA:BB:CC:DD:EE:FF")

    def test_saved_profile_password_retry_uses_stdin(self):
        secret = 'replacement:password\\with"chars'
        with patch.object(backend.subprocess, "run", return_value=completed()) as run:
            backend.action({"action": "connect", "interface": "wlan0", "uuid": "saved",
                            "bssid": "AA:BB:CC:DD:EE:FF", "password": secret})
        args, kwargs = run.call_args
        self.assertEqual(args[0][-2:], ["passwd-file", "/dev/stdin"])
        self.assertIn("saved", args[0])
        self.assertNotIn(secret, str(args))
        self.assertEqual(kwargs["input"], "802-11-wireless-security.psk:" + secret + "\n")

    def test_newline_password_rejected_before_subprocess(self):
        with patch.object(backend.subprocess, "run") as run:
            for password in ("secret\nother", "secret\rother", "secret\x00"):
                with self.assertRaises(backend.NetworkError):
                    backend.action({"action": "connect", "interface": "wlan0",
                                    "bssid": "AA:BB:CC:DD:EE:FF", "password": password})
            run.assert_not_called()

    def test_simple_actions(self):
        cases = [({"action": "wired", "interface": "eth0"}, ("device", "connect", "eth0")),
                 ({"action": "wifi", "enabled": False}, ("radio", "wifi", "off")),
                 ({"action": "scan", "interface": "wlan0"}, ("device", "wifi", "rescan", "ifname", "wlan0")),
                 ({"action": "disconnect", "interface": "wlan0"}, ("device", "disconnect", "wlan0")),
                 ({"action": "forget", "uuid": "p"}, ("connection", "delete", "uuid", "p"))]
        for request, command in cases:
            with patch.object(backend, "nm") as nm:
                backend.action(request)
                nm.assert_called_once_with(*command)

    def test_wired_rejects_invalid_interface_before_subprocess(self):
        with patch.object(backend.subprocess, "run") as run:
            for interface in (None, "", "-eth0", "eth0\n", "eth0\r", "eth0\x00", 42):
                with self.subTest(interface=interface), self.assertRaises(backend.NetworkError):
                    backend.action({"action": "wired", "interface": interface})
            run.assert_not_called()

    def test_invalid_requests_do_not_run_commands(self):
        requests = [None, [], {}, {"action": "wifi", "enabled": 1},
                    {"action": "connect", "interface": "wlan0", "bssid": "not-a-bssid"},
                    {"action": "forget", "uuid": "-profile"}]
        with patch.object(backend.subprocess, "run") as run:
            for request in requests:
                with self.subTest(request=request), self.assertRaises(backend.NetworkError):
                    backend.action(request)
            run.assert_not_called()

    def test_errors_never_echo_secrets(self):
        request = {"action": "connect", "interface": "wlan0", "bssid": "AA:BB:CC:DD:EE:FF",
                   "uuid": "p", "password": "super-secret"}
        with patch.object(backend.sys, "argv", ["network-control", "action"]), \
                patch.object(backend.sys, "stdin", io.StringIO(json.dumps(request))), \
                patch.object(backend.subprocess, "run", return_value=completed("super-secret", 1, "super-secret")), \
                contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(backend.main(), 1)
        self.assertFalse(json.loads(output.getvalue())["ok"])
        self.assertNotIn("super-secret", output.getvalue())

    def test_timeout_is_sanitized(self):
        with patch.object(backend.subprocess, "run", side_effect=subprocess.TimeoutExpired("secret", 25)):
            with self.assertRaisesRegex(backend.NetworkError, "timed out"):
                backend.nm("radio", "wifi")


if __name__ == "__main__":
    unittest.main()

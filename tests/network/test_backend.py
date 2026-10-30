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
            if fields.startswith("GENERAL.CON-UUID"):
                iface = tail[-1]
                if iface == "lo":
                    return completed(line("GENERAL.CON-UUID", "--"))
                return completed(line("GENERAL.CON-UUID", "wired-uuid" if iface == "eth0" else "wifi-uuid") +
                                 line("IP4.ADDRESS[1]", "192.0.2.3/24") +
                                 line("IP4.GATEWAY", "192.0.2.1") + line("IP4.DNS[1]", "1.1.1.1") +
                                 line("IP6.DNS[1]", "2606:4700:4700::1111"))
            if fields.startswith("GENERAL.DEFAULT"):
                default = wired_default if tail[-1] == "wired-uuid" else wifi_default
                return completed(line("GENERAL.DEFAULT", "yes" if default else "no") +
                                 line("GENERAL.DEFAULT6", "no"))
            if fields == "802-11-wireless.band":
                return completed(line(fields, "a"))
            if fields.startswith("SSID,BSSID,SIGNAL"):
                return completed(line(" café:home\\net ", "AA:BB:CC:DD:EE:FF", 81, "WPA2", "5180 MHz", "*", "wlan0"))
            self.fail(f"Unexpected nmcli call: {args}")
        return respond

    def test_wired_default_preferred_but_wifi_still_active(self):
        with patch.object(backend.subprocess, "run", side_effect=self.status_runner()), \
                patch.object(backend, "counter", return_value=123):
            data = backend.status()
        self.assertTrue(data["available"], data)
        self.assertTrue(data["wifiEnabled"])
        self.assertEqual(data["active"]["interface"], "eth0")
        self.assertEqual(data["wifiBand"], "a")
        self.assertEqual(data["active"]["rxBytes"], 123)
        self.assertEqual(data["active"]["dns"], ["1.1.1.1", "2606:4700:4700::1111"])
        wifi = data["networks"][0]
        self.assertEqual(wifi["ssid"], " café:home\\net ")
        self.assertEqual(wifi["uuid"], "wifi-uuid")
        self.assertEqual(wifi["frequency"], 5180)
        self.assertTrue(wifi["known"] and wifi["active"])

    def test_wifi_default_beats_nondefault_wired(self):
        with patch.object(backend.subprocess, "run", side_effect=self.status_runner(wired_default=False)):
            data = backend.status()
        self.assertEqual(data["active"]["interface"], "wlan0")
        self.assertEqual(data["active"]["band"], "a")

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

    def test_dns_both_stacks_and_reset(self):
        for mode in ("auto", "cloudflare", "google", "custom"):
            with self.subTest(mode=mode), patch.object(backend, "nm") as nm, patch.object(backend, "apply") as apply:
                backend.action({"action": "dns", "uuid": "profile", "mode": mode,
                                "servers": "9.9.9.9,2620:fe::fe"})
                command = nm.call_args.args
                self.assertEqual(command[:4], ("connection", "modify", "uuid", "profile"))
                settings = dict(zip(command[4::2], command[5::2]))
                for version in (4, 6):
                    self.assertEqual(settings[f"ipv{version}.ignore-auto-dns"], "no" if mode == "auto" else "yes")
                    if mode == "auto":
                        self.assertEqual(settings[f"ipv{version}.dns"], "")
                    else:
                        self.assertTrue(settings[f"ipv{version}.dns"])
                apply.assert_called_once_with("profile")

    def test_dns_mode_from_profile_not_runtime_resolver(self):
        self.assertEqual(backend.dns_mode({"ipv4.ignore-auto-dns": ["no"],
                                           "ipv6.ignore-auto-dns": ["no"]}), "auto")
        for mode in ("cloudflare", "google"):
            addresses = backend.DNS_PRESETS[mode].split()
            profile = {"ipv4.ignore-auto-dns": ["yes"], "ipv6.ignore-auto-dns": ["yes"],
                       "ipv4.dns": [", ".join(reversed(addresses[:2]))],
                       "ipv6.dns": [", ".join(addresses[2:])]}
            self.assertEqual(backend.dns_mode(profile), mode)
            profile["ipv6.ignore-auto-dns"] = ["no"]
            self.assertEqual(backend.dns_mode(profile), "custom")
        self.assertEqual(backend.dns_mode({"ipv4.dns": ["9.9.9.9"]}), "custom")
        self.assertEqual(backend.dns_mode({"ipv4.ignore-auto-dns": ["yes"]}), "custom")

    def test_dns_ipv4_only_clears_ipv6_servers(self):
        with patch.object(backend, "nm") as nm, patch.object(backend, "apply"):
            backend.action({"action": "dns", "uuid": "p", "mode": "custom", "servers": "9.9.9.9"})
        self.assertEqual(nm.call_args.args[-2:], ("ipv6.dns", ""))

    def test_invalid_dns_and_band_no_mutation(self):
        requests = [{"action": "dns", "mode": "custom", "servers": value, "uuid": "p"}
                    for value in ("", "not-an-ip", "1.1.1.1;bad", [], "fe80::1%wlan0")]
        # Scoped IPv6 literals cannot be persisted as DNS servers.
        requests += [{"action": "band", "uuid": "p", "band": value} for value in ("5GHz", "", None)]
        with patch.object(backend, "nm") as nm:
            for request in requests:
                with self.subTest(request=request), self.assertRaises(backend.NetworkError):
                    backend.action(request)
            nm.assert_not_called()

    def test_band_reconnect_and_auto_clear(self):
        for band in ("auto", "bg", "a"):
            with patch.object(backend, "nm") as nm, \
                    patch.object(backend, "rows", return_value=[["p", "wlan0"]]):
                backend.action({"action": "band", "uuid": "p", "band": band})
                self.assertEqual(nm.call_args_list[0].args,
                                 ("connection", "modify", "uuid", "p", "802-11-wireless.band", "" if band == "auto" else band))
                self.assertEqual(nm.call_args_list[1].args, ("connection", "up", "uuid", "p", "ifname", "wlan0"))

    def test_reapply_fallback(self):
        with patch.object(backend, "rows", return_value=[["p", "wlan0"]]), \
                patch.object(backend, "nm", side_effect=[backend.NetworkError("failed"), ""]) as nm:
            backend.apply("p")
        self.assertEqual(nm.call_args.args, ("connection", "up", "uuid", "p", "ifname", "wlan0"))

    def test_simple_actions(self):
        cases = [({"action": "wifi", "enabled": False}, ("radio", "wifi", "off")),
                 ({"action": "scan", "interface": "wlan0"}, ("device", "wifi", "rescan", "ifname", "wlan0")),
                 ({"action": "disconnect", "interface": "wlan0"}, ("device", "disconnect", "wlan0")),
                 ({"action": "forget", "uuid": "p"}, ("connection", "delete", "uuid", "p"))]
        for request, command in cases:
            with patch.object(backend, "nm") as nm:
                backend.action(request)
                nm.assert_called_once_with(*command)

    def test_probe_interface_and_partial_loss(self):
        output = "3 packets transmitted, 2 received, 33.3333% packet loss\nrtt min/avg/max/mdev = 2.1/3.2/4.3/1.1 ms\n"
        with patch.object(backend.subprocess, "run", return_value=completed(output, 1)) as run:
            result = backend.probe("wlan0")
        self.assertEqual(result, {"pingMs": 3.2, "packetLoss": 33.3333})
        self.assertEqual(run.call_args.args[0][-3:], ["-I", "wlan0", "1.1.1.1"])
        self.assertEqual(run.call_args.kwargs["timeout"], 9)
        with patch.object(backend.subprocess, "run", return_value=completed("", 1)):
            self.assertEqual(backend.probe(), {"pingMs": None, "packetLoss": 100.0})

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

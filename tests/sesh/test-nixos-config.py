#!/usr/bin/env python3
"""Run with: python3 tests/sesh/test-nixos-config.py (requires Nix and tmux)."""
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time

repo = Path(__file__).resolve().parents[2]
config = json.loads(subprocess.check_output([
    "nix", "--extra-experimental-features", "nix-command flakes", "eval", "--json",
    '.#nixosConfigurations.tallyho.config.hjem.users.adrien.files.".config/sesh/sesh.toml".source.value',
], cwd=repo))
session, = config["session"]
assert session["name"] == "nixos config"
assert session["path"] == "~/nixos"

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    (root / "nixos").mkdir()
    log = root / "started"
    for app in ("pi", "touffu"):
        mock = root / app
        mock.write_text(f'#!/bin/sh\necho {app} >> "{log}"\n')
        mock.chmod(0o755)
    socket = str(root / "tmux.sock")
    command = session["startup_command"]
    command = re.sub(r"/nix/store/[^ /]+/bin/tmux", f"tmux -S {socket}", command)
    command = re.sub(r"/nix/store/[^ /]+/bin/(pi|touffu)",
                     lambda match: str(root / match[1]), command)
    env = dict(os.environ, HOME=directory)

    def tmux(*args):
        return subprocess.check_output(["tmux", "-S", socket, *args], env=env, text=True)

    try:
        tmux("-f", "/dev/null", "new-session", "-d", "-s", session["name"],
             "-x", "160", "-y", "48", "-c", str(root / "nixos"))
        tmux("set-option", "-g", "pane-base-index", "1")
        subprocess.run(["bash", "-c", command], env=env, cwd=root / "nixos", check=True)
        for _ in range(100):
            if log.exists() and sorted(log.read_text().splitlines()) == ["pi", "touffu"]:
                break
            time.sleep(0.02)
        assert sorted(log.read_text().splitlines()) == ["pi", "touffu"]
        panes = tmux("list-panes", "-t", "nixos config:work", "-F",
                     "#{pane_index} #{pane_left} #{pane_top} #{pane_current_path}").splitlines()
        assert len(panes) == 3, panes
        geometry = [line.split(maxsplit=3) for line in panes]
        assert [row[0] for row in geometry] == ["1", "2", "3"], geometry
        assert geometry[0][1:3] == ["0", "0"], geometry
        assert int(geometry[1][1]) > 0 and geometry[1][2] == "0", geometry
        assert geometry[2][1] == geometry[1][1] and int(geometry[2][2]) > 0, geometry
        assert all(row[3] == str(root / "nixos") for row in geometry), geometry
    finally:
        subprocess.run(["tmux", "-S", socket, "kill-server"], check=False)

print("PASS: nixos config session, startup commands and three-pane layout")

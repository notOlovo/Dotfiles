#!/usr/bin/env python3
# "Now playing" for Waybar — a replacement for the built-in mpris module, which crashes
# in libplayerctl (Waybar 0.15) when a player appears or disappears.
# playerctl --follow prints a line on every change; an empty one means no players.
import json
import subprocess
import sys

ICONS = {"spotify": "\U000F04C7", "firefox": "\U000F0239"}
DEFAULT = "\U000F075A"
PAUSED = "\U000F03E4"
MAX = 32


def out(text="", tooltip="", cls=""):
    print(json.dumps({"text": text, "tooltip": tooltip, "class": cls}), flush=True)


fmt = "{{status}}\t{{playerName}}\t{{artist}}\t{{title}}"
proc = subprocess.Popen(
    ["playerctl", "--follow", "metadata", "--format", fmt],
    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
)
out()
for line in proc.stdout:
    parts = line.rstrip("\n").split("\t")
    if len(parts) != 4 or parts[0] not in ("Playing", "Paused"):
        out()
        continue
    status, player, artist, title = parts
    dyn = " — ".join(x for x in (title, artist) if x)
    if len(dyn) > MAX:
        dyn = dyn[: MAX - 1] + "…"
    icon = PAUSED if status == "Paused" else ICONS.get(player, DEFAULT)
    out(f"{icon} {dyn}", f"{player}: {artist} — {title}", status.lower())
sys.exit(proc.wait())

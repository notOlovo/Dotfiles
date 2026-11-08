#!/usr/bin/env bash
# Screen lock: Quickshell (qs -c lock), hyprlock as a fallback.
# If the Quickshell lock screen isn't up within 3 seconds, hyprlock starts,
# so the session is never left unlocked.

# Already locked — no second lock screen
pgrep -f "qs -c lock" >/dev/null && exit 0
pgrep -x hyprlock >/dev/null && exit 0

qs -c lock >/dev/null 2>&1 &
pid=$!

for _ in {1..30}; do
    sleep 0.1
    kill -0 "$pid" 2>/dev/null || break
    qs log --pid "$pid" 2>/dev/null | grep -q "Configuration Loaded" && { wait "$pid"; exit 0; }
done

# It didn't load — remove it and lock with the reliable hyprlock
kill "$pid" 2>/dev/null
exec hyprlock

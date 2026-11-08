#!/usr/bin/env bash
# Run Waybar and restart it after a crash (segfault etc.).
# A normal exit (pkill, SIGTERM, logging out) is not restarted.
while true; do
    waybar "$@"
    code=$?
    (( code == 0 || code == 143 || code == 130 )) && exit "$code"
    echo "waybar crashed (code $code), restarting" >&2
    sleep 1
done

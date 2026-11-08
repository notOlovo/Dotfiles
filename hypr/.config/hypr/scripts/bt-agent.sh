#!/usr/bin/env bash
# Bluetooth agent for pairing without popups ("Just Works"):
# without an agent BlueZ rejects pairing (Authentication Rejected).
# bluetoothctl keeps the agent while its stdin is open.
{
    echo "agent NoInputNoOutput"
    echo "default-agent"
    exec sleep infinity
} | bluetoothctl >/dev/null

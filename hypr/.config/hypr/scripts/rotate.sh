#!/bin/bash
# Rotate the screen by 180° (Win + Shift + R)
eval $(hyprctl monitors | awk '/^Monitor/ {m=$2} /scale:/ {s=$2} /transform:/ {t=$2; print "M="m" S="s" T="t; exit}')
hyprctl keyword monitor "$M",preferred,auto,"$S",transform,$(((T + 2) % 4))

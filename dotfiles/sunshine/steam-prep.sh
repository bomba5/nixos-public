#!/usr/bin/env bash
# Prep script for Sunshine Handheld app:
# Switches to workspace 10 and launches Steam in Big Picture mode.
# Uses systemd-run to avoid inheriting Sunshine's capSysAdmin capabilities
# which break Steam's bubblewrap sandbox.

hyprctl dispatch workspace 10
systemd-run --user --no-block -- steam steam://open/bigpicture

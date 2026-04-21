# Module: modules/profiles/graphical.nix
# Purpose: Desktop profile layering graphical stack on top of base (Hyprland, Avahi, Bluetooth, GUI desktop defaults).
# Options: No new options; depends on modules.system.* via imported modules.
# Usage: Import in workstation hosts to enable the full desktop experience.
{ config, pkgs, ... }:

{
  imports = [
    ./base.nix # Imports the base profile
    ../desktop/core.nix
    ../desktop/hyprland.nix
    ../audio/audio.nix
    ../services/avahi.nix
    ../services/bluetooth.nix
  ];
}

# Module: modules/desktop/gui-desktop.nix
# Purpose: Desktop-only boot/greeter polish (Plymouth splash, greetd with tuigreet).
# Options: No custom options.
# Usage: Import in desktop hosts that need a lightweight login greeter and quiet boot.
{ pkgs, ... }:

{
  boot.plymouth.enable = true;
  boot.plymouth.theme = "bgrt";

  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "systemd.show_status=auto"
    "rd.udev.log_level=3"
  ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time";
        user = "greeter";
      };
    };
  };
}

# Module: modules/services/hp-printing.nix
# Purpose: Enable printing with HPLIP drivers and mDNS discovery for HP printers.
# Options: No custom options.
# Usage: Import on hosts that need HP printer support; pulls in Avahi helper.
{ pkgs, ... }:

{
  services.printing.enable = true;

  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  services.printing.drivers = [ pkgs.hplip ];

  # cups-browsed hangs on shutdown when network is unavailable; cap the wait.
  systemd.services.cups-browsed.serviceConfig.TimeoutStopSec = 5;
}

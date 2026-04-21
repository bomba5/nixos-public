# Module: modules/services/avahi.nix
# Purpose: Enable Avahi/mDNS for service discovery.
# Options: No custom options.
# Usage: Import on LAN-connected machines needing mDNS (included in graphical profile).
{
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
}

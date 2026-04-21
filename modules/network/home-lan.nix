# Module: modules/network/home-lan.nix
# Purpose: Static networking defaults (gateway / nameservers) for hosts on the home LAN.
# Options: No custom options.
# Usage: Import on hosts that should use fixed gateway/DNS instead of DHCP.
#
# Replace the example IPs below with your own router / local resolver.
{
  networking = {
    defaultGateway = "192.168.1.1";
    nameservers = [
      "192.168.1.31"
      "192.168.1.1"
    ];
    networkmanager.enable = true;
  };
}

# Module: modules/network/generic.nix
# Purpose: Generic NetworkManager-based networking plus static host mappings for LAN devices.
# Options: No custom options.
# Usage: Import on roaming/desktop hosts needing DHCP via NetworkManager and shared hosts file.
#
# Replace the example hostnames / IPs below with your own LAN layout.
{
  networking = {
    networkmanager.enable = true;

    hosts = {
      # Replace with your real LAN entries.
      "192.168.1.1"  = [ "router" ];
      "192.168.1.10" = [ "server" ];
      "192.168.1.11" = [ "nas" ];
      "192.168.1.20" = [ "workstation" ];
      "192.168.1.21" = [ "laptop" ];
      "192.168.1.30" = [ "home-automation" ];
      "192.168.1.31" = [ "dns" ];
      "192.168.1.40" = [ "vpn-gateway" ];
    };
  };
}

# Module: modules/services/sunshine.nix
# Purpose: Enable Sunshine game/desktop streaming with CUDA support and firewall openings.
# Options: No custom options.
# Usage: Import on hosts providing game streaming (e.g., GPU desktops/servers).
{ pkgs, ... }:

{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    package = pkgs.sunshine.override { cudaSupport = true; };
  };
}

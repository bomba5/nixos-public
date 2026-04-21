# Module: modules/vpn/home-wireguard.nix
# Purpose: Install WireGuard tooling and deploy a home-LAN WireGuard config.
#
# ⚠️  PLACEHOLDER ⚠️
# This module is intentionally stripped to a skeleton. The real deployment
# reads `home.conf` from a sops-encrypted secret and drops it at
# /etc/wireguard/home.conf. That logic is not included here because secrets
# are per-user — you have to wire up your own sops secret first.
#
# To use this pattern:
#   1. Create a WireGuard config (e.g. from `wg-quick genconf` or your peer).
#   2. Add it as a secret in secrets/secrets.yaml:
#        wireguard_home: |
#          [Interface]
#          PrivateKey = ...
#          Address = ...
#          [Peer]
#          PublicKey = ...
#          Endpoint = ...
#          AllowedIPs = ...
#   3. Reference it from this module:
#        sops.secrets.wireguard_home = {};
#        environment.etc."wireguard/home.conf".source =
#          config.sops.secrets.wireguard_home.path;
#   4. NetworkManager auto-detects files in /etc/wireguard/ as VPN connections.
{ config, pkgs, ... }:

let
  sysCfg = config.modules.system;
in
{
  # Install wg tools for the main user (safe to enable; no secrets required).
  home-manager.users.${sysCfg.mainUser} = {
    home.packages = with pkgs; [
      wireguard-tools
    ];
  };
}

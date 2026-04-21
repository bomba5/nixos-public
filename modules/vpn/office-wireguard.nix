# Module: modules/vpn/office-wireguard.nix
# Purpose: Install WireGuard tooling (+ sccache config) and deploy an office/work WireGuard config.
#
# ⚠️  PLACEHOLDER ⚠️
# This module is intentionally stripped to a skeleton. The real deployment
# reads `office.conf` from a sops-encrypted secret and drops it at
# /etc/wireguard/office.conf. That logic is not included here because secrets
# are per-user — you have to wire up your own sops secret first.
#
# To use this pattern:
#   1. Create a WireGuard config for your office VPN.
#   2. Add it as a secret in secrets/secrets.yaml:
#        wireguard_office: |
#          [Interface] ... [Peer] ...
#   3. Reference it from this module:
#        sops.secrets.wireguard_office = {};
#        environment.etc."wireguard/office.conf".source =
#          config.sops.secrets.wireguard_office.path;
#   4. NetworkManager auto-detects files in /etc/wireguard/ as VPN connections.
#
# The sccache bootstrap below is included because distributed C/C++ compilation
# is a common reason for wanting an office VPN in the first place. Remove it
# if not relevant to you.
{ config, pkgs, lib, ... }:

let
  sysCfg = config.modules.system;
in
{
  home-manager.users.${sysCfg.mainUser} =
    { lib, ... }:
    {
      home.packages = with pkgs; [
        wireguard-tools
        sccache
      ];

      home.activation.installSccacheConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu

        confSrc='/etc/nixos/dotfiles/sccache/config'
        targetDir="$HOME/.config/sccache"
        target="$targetDir/config"

        install -m 700 -d "$targetDir"

        [ -L "$target" ] && rm -f "$target"

        if [ -f "$confSrc" ]; then
          install -m 644 "$confSrc" "$target"
        fi
      '';
    };
}

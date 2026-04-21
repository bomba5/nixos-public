# Module: modules/virtualisation/virtualbox.nix
# Purpose: Enable VirtualBox host with Extension Pack and add main user to vboxusers.
# Options: No custom options; uses modules.system.mainUser for group membership.
# Usage: Import on hosts needing VirtualBox virtualization.
{ config, pkgs, lib, ... }:

let
  sysCfg = config.modules.system;
in
{
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };

  users.users.${sysCfg.mainUser}.extraGroups = [ "vboxusers" ];
}

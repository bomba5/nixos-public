# Module: modules/virtualisation/docker.nix
# Purpose: Enable Docker daemon and add the main user to the docker group.
# Options: No custom options; uses modules.system.mainUser to add group membership.
# Usage: Import where container runtime is required (servers, dev machines).
{ config, pkgs, lib, ... }:

let
  sysCfg = config.modules.system;
in
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    rootless.enable = false;
  };

  users.users.${sysCfg.mainUser}.extraGroups = [ "docker" ];
}

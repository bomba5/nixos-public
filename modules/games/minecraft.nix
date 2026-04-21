# Module: modules/games/minecraft.nix
# Purpose: Install PrismLauncher for Minecraft via Home Manager.
# Options: No custom options; uses modules.system.mainUser.
# Usage: Import on hosts where Minecraft launcher should be available.
{ config, pkgs, lib, ... }:

let
  sysCfg = config.modules.system;
in
{
  home-manager.users.${sysCfg.mainUser} = {
    home.packages = with pkgs; [
      prismlauncher
    ];
  };
}

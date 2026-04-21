# Module: modules/desktop/hyprland.nix
# Purpose: Enable Hyprland and wire host/mode-specific config symlinks for desktops/servers.
# Options: modules.desktop.hyprland.{enable,mode,hostName} to control enablement and config selection.
# Usage: Import in desktop hosts; set modules.desktop.hyprland.enable = true and hostName/mode per machine.
{ config, pkgs, lib, ... }:

let
  cfg = config.modules.desktop.hyprland;
  sysCfg = config.modules.system;
  confSuffix = if cfg.mode == "server" then "server" else cfg.hostName;
in
{
  options.modules.desktop.hyprland = {
    enable = lib.mkEnableOption "hyprland";
    mode = lib.mkOption {
      type = lib.types.enum [ "desktop" "server" ];
      default = "desktop";
      description = "Mode for hyprland, e.g. desktop or server.";
    };
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "Hostname of the machine, used to load specific hyprland config.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland.enable = true;
    programs.hyprland.withUWSM = true;

    home-manager.users.${sysCfg.mainUser} = { config, ... }: {
      home.file = lib.foldl' lib.recursiveUpdate {} ([
        # Common configs
        {
          ".config/hypr/hyprland.conf".source =
            config.lib.file.mkOutOfStoreSymlink "${sysCfg.dotfilesPath}/dotfiles/desktop/hypr/hyprland.conf";
          ".config/hypr/hyprpaper.conf".source =
            config.lib.file.mkOutOfStoreSymlink "${sysCfg.dotfilesPath}/dotfiles/desktop/hypr/hyprpaper.conf";

          # Mode-specific config
          ".config/hypr/mainmod.conf".source =
            config.lib.file.mkOutOfStoreSymlink "${sysCfg.dotfilesPath}/dotfiles/desktop/hypr/mainmod-${cfg.mode}.conf";

          # Host/mode-specific configs
          ".config/hypr/monitors.conf".source =
            config.lib.file.mkOutOfStoreSymlink "${sysCfg.dotfilesPath}/dotfiles/desktop/hypr/monitors-${confSuffix}.conf";
          ".config/hypr/exec.conf".source =
            config.lib.file.mkOutOfStoreSymlink "${sysCfg.dotfilesPath}/dotfiles/desktop/hypr/exec-${confSuffix}.conf";
          ".config/hypr/windowrulesv2.conf".source =
            config.lib.file.mkOutOfStoreSymlink "${sysCfg.dotfilesPath}/dotfiles/desktop/hypr/windowrulesv2-${confSuffix}.conf";
        }
      ]
      ++ (lib.optionals (cfg.mode == "desktop") [
        # Hyprlock is desktop-specific
        {
          ".config/hypr/hyprlock.conf".source =
            config.lib.file.mkOutOfStoreSymlink "${sysCfg.dotfilesPath}/dotfiles/desktop/hypr/hyprlock.conf";
        }
        # Hypridle is desktop-specific
        {
          ".config/hypr/hypridle.conf".source =
            config.lib.file.mkOutOfStoreSymlink "${sysCfg.dotfilesPath}/dotfiles/desktop/hypr/hypridle-${cfg.hostName}.conf";
        }
            ]));
          };
        };
      }

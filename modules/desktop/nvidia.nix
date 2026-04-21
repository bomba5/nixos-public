# Module: modules/desktop/nvidia.nix
# Purpose: Enable proprietary NVIDIA stack (driver, container toolkit, udev rules, optional power cap).
# Options: modules.desktop.nvidia.powerCapWatts — set to limit GPU power draw (null = no cap).
# Usage: Import in hosts with NVIDIA GPUs; typically alongside graphical profile.
{ config, pkgs, lib, ... }:

let
  cfg = config.modules.desktop.nvidia;
in
{
  options.modules.desktop.nvidia = {
    powerCapWatts = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "GPU power cap in watts via nvidia-smi -pl. null means no cap.";
    };
  };

  config = {
    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    hardware.nvidia-container-toolkit.enable = true;

    services.xserver.videoDrivers = [ "nvidia" ];

    services.udev.extraRules = ''
      KERNEL=="nvidia*", GROUP="video", MODE="0660"
      KERNEL=="nvidia-caps", GROUP="video", MODE="0660"
    '';

    systemd.services.nvidia-power-cap = lib.mkIf (cfg.powerCapWatts != null) {
      description = "Set NVIDIA GPU Power Cap";
      wantedBy = [ "display-manager.service" ];
      after = [ "display-manager.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/run/current-system/sw/bin/nvidia-smi -pl ${toString cfg.powerCapWatts}";
      };
    };
  };
}

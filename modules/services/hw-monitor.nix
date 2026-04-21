# Module: modules/services/hw-monitor.nix
# Purpose: Periodic hardware telemetry logging (CPU/GPU temps, power, fans) for crash diagnosis.
# Options: modules.services.hwMonitor.enable, .intervalSec
# Usage: Import in hosts where you need thermal/power data (e.g. gaming desktops).
{ config, pkgs, lib, ... }:

let
  cfg = config.modules.services.hwMonitor;

  nvidiaSmiBin = "/run/current-system/sw/bin/nvidia-smi";

  monitorScript = pkgs.writeShellScript "hw-monitor" ''
    set -uo pipefail

    gpu=""
    if [ -x "${nvidiaSmiBin}" ]; then
      gpu=$(${nvidiaSmiBin} \
        --query-gpu=temperature.gpu,fan.speed,power.draw,power.limit,clocks.gr,clocks.mem,utilization.gpu,utilization.memory \
        --format=csv,noheader,nounits 2>/dev/null || echo "error")
    fi

    cpu=""
    for f in /sys/class/hwmon/hwmon*/temp*_input; do
      [ -f "$f" ] || continue
      label=""
      label_file="''${f%_input}_label"
      if [ -f "$label_file" ]; then
        label=$(cat "$label_file")
      else
        label=$(basename "$(dirname "$f")")/$(basename "$f" _input)
      fi
      val=$(cat "$f")
      temp=$(( val / 1000 ))
      cpu="$cpu $label:''${temp}C"
    done

    echo "HW_MONITOR gpu=[$gpu] cpu=[$cpu]"
  '';
in
{
  options.modules.services.hwMonitor = {
    enable = lib.mkEnableOption "periodic hardware telemetry logging";

    intervalSec = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Sampling interval in seconds.";
    };
  };

  config = lib.mkIf cfg.enable {
    # lm_sensors for CPU temperature reading
    environment.systemPackages = [ pkgs.lm_sensors ];

    systemd.services.hw-monitor = {
      description = "Log hardware temperatures and power draw";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${monitorScript}";
      };
    };

    systemd.timers.hw-monitor = {
      description = "Periodic hardware telemetry";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "${toString cfg.intervalSec}s";
        AccuracySec = "1s";
      };
    };
  };
}

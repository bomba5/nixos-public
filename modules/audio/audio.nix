# Module: modules/audio/audio.nix
# Purpose: Configure audio stack (PipeWire with Pulse/ALSA/JACK) and utilities/firmware.
# Options: No custom options; uses mkForce to ensure PipeWire is enabled.
# Usage: Import in hosts needing audio support; typically part of graphical profile.
{ lib, pkgs, ... }:

{
  hardware.alsa.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = lib.mkForce true;
    audio.enable = true;
    pulse.enable = true;
    alsa.enable = true;
    jack.enable = true;
  };

  environment.systemPackages = with pkgs; [
    sof-firmware
    alsa-utils
    wireplumber
  ];
}

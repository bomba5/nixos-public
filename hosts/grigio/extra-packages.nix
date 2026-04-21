{ pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    moonlight-qt
    chiaki-ng
    kernelshark
    nextcloud-client
    mudlet
    poppler-utils
    freecad
    kicad
    msmtp
    oauth2ms
    bitwarden-desktop
    bitwarden-cli
  ];

  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;

  # For moonlight
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      libva
      libva-utils
    ];
  };
}

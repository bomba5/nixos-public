{ pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    moonlight-qt
    chiaki-ng
    freecad
    kicad
    wineWowPackages.stable
    winetricks
    meshlab
    nextcloud-client
    mudlet
    sshfs
    android-tools
    uv
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

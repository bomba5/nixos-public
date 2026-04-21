{ pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    kas
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
}

{ config, pkgs, lib, ... }:

let
  sysCfg = config.modules.system;
in
{
  nixpkgs.overlays = [
    (import ../../overlays/bambu-studio.nix)
  ];

  imports = [
    # Host-specific modules and config
    ./hardware-configuration.nix
    ./extra-packages.nix
    ./ssh-keys.nix # SSH keys for this host

    # Profiles
    ../../modules/profiles/graphical.nix # Base graphical desktop profile

    # Host-specific modules that are not part of the standard graphical profile
    ../../modules/services/hp-printing.nix # CUPS + HPLIP printing support
    ../../modules/network/generic.nix # Specific network config
    ../../modules/vpn/home-wireguard.nix # Specific VPN
    ../../modules/desktop/gui-desktop.nix # Desktop specific GUI enablement
    ../../modules/games/minecraft.nix # Specific game module
  ];

  # Define main user and dotfiles path for this host
  modules.system.mainUser = "bomba";
  modules.system.dotfilesPath = "/etc/nixos";

  # Hyprland configuration
  modules.desktop.hyprland = {
    enable = true;
    mode = "desktop";
    hostName = "gremo";
  };

  home-manager.users.${sysCfg.mainUser} =
    { config, pkgs, osConfig, ... }:
    {
      home.packages = [
        pkgs.bambu-studio
      ];

      home.file.".gitconfig" = lib.mkForce {
        text = ''
          [include]
            path = ${osConfig.sops.secrets.git_config.path}
          [user]
            email = user@example.com
            name = bomba
        '';
      };
    };

  # Host-specific system settings
  time.timeZone = "Europe/Copenhagen";
  environment.etc."timezone".text = "Europe/Copenhagen";
  console.keyMap = "it";

  networking = {
    hostName = "gremo";
    enableIPv6 = false;
    firewall.enable = false;
  };

  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  crypto.gpg.enable = true;

  # Keep system awake on idle; let hypridle handle lock + display off.
  services.logind.settings.Login = {
    IdleAction = "ignore";
    IdleActionSec = 0;
  };

  # Prevent any suspend/hibernate targets from being reached.
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glibc
    stdenv.cc.cc
  ];

  boot.kernel.sysctl."net.ipv6.conf.eth0.disable_ipv6" = true;
  boot.extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
}

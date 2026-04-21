{ config, lib, pkgs, ... }:

let
  sysCfg = config.modules.system;
in
{
  imports = [
    # Host-specific modules and config
    ./hardware-configuration.nix
    ./extra-packages.nix
    ./ssh-keys.nix # SSH keys for this host

    # Profiles
    ../../modules/profiles/graphical.nix # Base graphical desktop profile

    # Host-specific modules that are not part of the standard graphical profile
    ../../modules/network/generic.nix # Specific network config
    ../../modules/vpn/home-wireguard.nix # Specific VPN
    ../../modules/desktop/gui-desktop.nix # Desktop specific GUI enablement
    ../../modules/games/minecraft.nix # Specific game module
    ../../modules/virtualisation/virtualbox.nix # Specific virtualization
    ../../modules/vpn/office-wireguard.nix # Specific VPN (office)
    ../../modules/development/embedded-bsp.nix # Dev tools
    ../../modules/development/segger.nix # Dev tools
    ../../modules/services/intune.nix    # Corporate Intune enrollment (adapted from niels/host)
  ];

  # Define main user and dotfiles path for this host
  modules.system.mainUser = "bomba";
  modules.system.dotfilesPath = "/etc/nixos";

  # Hyprland configuration
  modules.desktop.hyprland = {
    enable = true;
    mode = "desktop";
    hostName = "grigio";
  };

  home-manager.users.${sysCfg.mainUser} =
    { config, osConfig, ... }:
    {
      #home.file = {
      #  "Pictures/wallpapers/wallpaper.png".source =
      #    lib.mkForce ../../dotfiles/desktop/wallpapers/bomba.png;
      #};

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
  console.keyMap = "us";

  networking = {
    hostName = "grigio";
    enableIPv6 = false;
    firewall.enable = false;
  };

  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  # Keep the machine awake when idle; hypridle already handles screen blank/lock.
  services.logind = {
    settings.Login = {
      IdleAction = "ignore";
      IdleActionSec = 0;
    };
    settings.Login.HandleLidSwitch = "ignore";
    settings.Login.HandleLidSwitchDocked = "ignore";
  };

  crypto.gpg.enable = true;
  
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glibc
    stdenv.cc.cc
  ];

  boot.kernel.sysctl."net.ipv6.conf.eth0.disable_ipv6" = true;
  boot.extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];

  services.xserver.xkb = {
    layout = "gb";
    variant = "extd";
  };

  # Workaround: mt7925e Wi-Fi driver occasionally times out during s2idle and
  # aborts the suspend. Unload it before suspend and reload on resume so manual
  # suspends can complete reliably.
  systemd.services.mt7925e-sleep-workaround = {
    description = "Unload mt7925e before suspend/resume";
    wantedBy = [ "sleep.target" ];
    before = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''${pkgs.bash}/bin/bash -c "${pkgs.kmod}/bin/modprobe -r mt7925e || true"'';
      ExecStop = ''${pkgs.bash}/bin/bash -c "${pkgs.kmod}/bin/modprobe mt7925e || true"'';
    };
  };

  # Office docking station specific hardware settings
  boot.kernelModules = [
    "thunderbolt"
    "usbnet"
    "cdc_ether"
    "r8152"
    "r8169"
  ];
  services.hardware.bolt.enable = true;
  hardware.enableAllFirmware = true;
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
  '';
}

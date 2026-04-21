{ config, lib, pkgs, ... }:

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
    ../../modules/profiles/graphical.nix # Full graphical desktop profile

    # Host-specific modules
    ../../modules/network/home-lan.nix # Specific network config
    ../../modules/network/generic.nix # LAN host mappings
    ../../modules/desktop/gui-desktop.nix # Desktop GUI (Plymouth, greetd)
    ../../modules/desktop/nvidia.nix # Nvidia setup
    ../../modules/services/sunshine.nix # Sunshine streaming
    ../../modules/services/hp-printing.nix # CUPS + HPLIP printing support
    ../../modules/ai/ollama.nix # Ollama with CUDA for local LLM
    #../../modules/ai/open-webui.nix # AI WebUI
    #../../modules/ai/comfyui.nix # AI ComfyUI
    ../../modules/games/minecraft.nix # Minecraft
    ../../modules/services/hw-monitor.nix # Hardware telemetry for crash diagnosis
    ../../modules/vpn/home-wireguard.nix # Home VPN
    ../../modules/vpn/office-wireguard.nix # Office VPN
    ../../modules/development/embedded-bsp.nix # Dev tools
  ];

  # Define main user and dotfiles path for this host
  modules.system.mainUser = "bomba";
  modules.system.dotfilesPath = "/etc/nixos";

  # Hyprland configuration
  modules.desktop.hyprland = {
    enable = true;
    mode = "desktop";
    hostName = "ghibli";
  };

  home-manager.users.${sysCfg.mainUser} =
    { config, lib, osConfig, pkgs, ... }:
    {
      home.packages = [
        pkgs.bambu-studio
      ];

      home.file = {
        ".gitconfig" = lib.mkForce {
          text = ''
            [include]
              path = ${osConfig.sops.secrets.git_config.path}
            [user]
              email = user@example.com
              name = bomba
          '';
        };

        ".config/sunshine/apps.json".source =
          config.lib.file.mkOutOfStoreSymlink "${sysCfg.dotfilesPath}/dotfiles/sunshine/apps.json";

        ".config/sunshine/assets/desktop.png".source = ../../dotfiles/sunshine/assets/desktop.png;
        ".config/sunshine/assets/handheld.png".source = ../../dotfiles/sunshine/assets/handheld.png;
        ".config/sunshine/steam-prep.sh" = {
          source = ../../dotfiles/sunshine/steam-prep.sh;
          executable = true;
        };
      };
    };

  # Host-specific system settings
  time.timeZone = "Europe/Copenhagen";
  environment.etc."timezone".text = "Europe/Copenhagen";
  console.keyMap = "us";

  networking = {
    hostName = "ghibli";

    # LAN interface temporarily disabled — this host has no wired connection in
    # its current room.  WiFi via NetworkManager is the only uplink for now.
    # Uncomment when LAN is available again (and remove defaultGateway override).
    # interfaces.enp42s0.ipv4.addresses = [
    #   {
    #     address = "192.168.1.25";
    #     prefixLength = 24;
    #   }
    # ];

    # Let NetworkManager/WiFi handle the default route instead of home-lan.nix's
    # static gateway (which would bind to the disconnected enp42s0).
    defaultGateway = lib.mkForce null;

    enableIPv6 = false;
    firewall.enable = false;
  };

  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  modules.services.hwMonitor.enable = true;

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

  # WoL disabled while LAN is disconnected.  Uncomment with the static IP above.
  # networking.interfaces."enp42s0".wakeOnLan.enable = true;

  # Auto-login so WoL boots straight into a graphical session (for Sunshine streaming).
  services.greetd.settings.initial_session = {
    command = "uwsm start hyprland-uwsm.desktop";
    user = "bomba";
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glibc
    stdenv.cc.cc
  ];

  # DeepCool AK400 Digital Pro cooler display
  services.hardware.deepcool-digital-linux.enable = true;
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3633", MODE="0666"
  '';

  boot.loader.systemd-boot.memtest86.enable = true;

  boot.kernel.sysctl."net.ipv6.conf.enp42s0.disable_ipv6" = true;
  boot.extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
}

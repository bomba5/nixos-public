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
    ../../modules/profiles/base.nix # Base system profile (no graphical desktop)

    # Host-specific modules
    ../../modules/network/home-lan.nix # Specific network config
    ../../modules/vpn/office-wireguard.nix # Specific VPN
    ../../modules/development/embedded-bsp.nix # Dev tools
  ];

  # Define main user and dotfiles path for this host
  modules.system.mainUser = "bomba";
  modules.system.dotfilesPath = "/etc/nixos";

  home-manager.users.${sysCfg.mainUser} =
    { config, lib, osConfig, ... }:
    {
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
      };
    };

  # Host-specific system settings
  time.timeZone = "Europe/Copenhagen";
  environment.etc."timezone".text = "Europe/Copenhagen";
  console.keyMap = "us";

  networking = {
    hostName = "karaburan";

    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.1.43";
        prefixLength = 24;
      }
    ];

    enableIPv6 = false;
    firewall.enable = false;
  };

  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  crypto.gpg.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glibc
    stdenv.cc.cc
  ];

  boot.kernel.sysctl."net.ipv6.conf.eth0.disable_ipv6" = true;

  # Ollama — local LLM inference for Bart's automated tasks
  # Reduces Anthropic API dependency for simple loops (heartbeat, formatting, parsing)
  services.ollama = {
    enable = true;
    acceleration = false; # CPU-only (no GPU on karaburan)
    host = "0.0.0.0"; # accessible from other machines on LAN
    port = 11434;
  };
}

# Module: modules/core.nix
# Purpose: Core system defaults (users, locale, base packages) shared by all hosts.
# Options: Defines modules.system.mainUser and modules.system.dotfilesPath for user/home-manager plumbing.
# Usage: Imported by base profile/hosts; override modules.system.* per host for usernames/paths.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.system;
in
{
  options.modules.system = {
    mainUser = lib.mkOption {
      type = lib.types.str;
      default = "bomba";
      description = "The main user of the system.";
    };
    dotfilesPath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos";
      description = "Absolute path to the dotfiles repository (for hot-reloading).";
    };
  };

  config = {
    nixpkgs.config.allowUnfree = true;

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    time.timeZone = "Europe/Copenhagen";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "en_GB.UTF-8/UTF-8"
      "da_DK.UTF-8/UTF-8"
      "C.UTF-8/UTF-8"
    ];

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "da_DK.UTF-8";
      LC_IDENTIFICATION = "da_DK.UTF-8";
      LC_MEASUREMENT = "da_DK.UTF-8";
      LC_MONETARY = "da_DK.UTF-8";
      LC_NAME = "da_DK.UTF-8";
      LC_NUMERIC = "da_DK.UTF-8";
      LC_PAPER = "da_DK.UTF-8";
      LC_TELEPHONE = "da_DK.UTF-8";
      LC_TIME = "da_DK.UTF-8";
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    environment.systemPackages = with pkgs; [
      kitty.terminfo # so SSH sessions from kitty don't break TERM=xterm-kitty
      # Custom credential helper to read secrets from sops without attempting writes
      (writeScriptBin "git-credential-sops-readonly" ''
        #!${pkgs.bash}/bin/bash
        if [ "$1" == "get" ]; then
          ${pkgs.git}/bin/git credential-store --file=${config.sops.secrets.git_credentials.path} get
        fi
        exit 0
      '')
      vim
      fzf
      fastfetch
      ripgrep
      nodejs
      clang
      clang-tools
      git
      wget
      curl
      htop
      btop
      tree
      just
      python3
      file
      bash
      unzip
      zip
      iperf
      ffmpeg
      alsa-utils
      coreutils-full
      bc
      usbutils
      wakeonlan
    ];

    users.groups.${cfg.mainUser} = {
      gid = 1000;
    };

    users.users.${cfg.mainUser} = {
      isNormalUser = true;
      uid = 1000;
      group = cfg.mainUser;
      extraGroups = [
        "wheel"
        "video"
        "render"
        "networkmanager"
        "audio"
        "dialout"
        "input"
        "bluetooth"
      ];
    };

    console = {
      font = "Lat2-Terminus16";
    };

    sops.secrets.git_credentials = {
      owner = cfg.mainUser;
      mode = "0400";
    };
    sops.secrets.github_token = {
      owner = cfg.mainUser;
      mode = "0400";
    };
    sops.secrets.git_config = {
      owner = cfg.mainUser;
      mode = "0400";
    };

    home-manager.users.${cfg.mainUser} =
      { config, osConfig, ... }:
      {
        home.stateVersion = "25.05";

        home.sessionPath = [
          "$HOME/.npm-global/bin"
          "$HOME/.local/bin" 
        ];

        home.file = {
          ".gitconfig".source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.secrets.git_config.path;
          ".git-credentials".source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.secrets.git_credentials.path;
          ".config/github-token.env".source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.secrets.github_token.path;
        };
      };

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "backup";

    # Populate /bin, /usr/bin, etc. for compatibility
    services.envfs.enable = true;

    system.stateVersion = "25.05";
  };
}

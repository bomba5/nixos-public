# Module: modules/crypto/gpg.nix
# Purpose: Import sops-managed GPG keys for users and enforce Git signing defaults.
# Options: crypto.gpg.enable to toggle key import/signing setup.
# Usage: Import where shared GPG identity is needed; set crypto.gpg.enable = true.
{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.crypto.gpg;
  sysCfg = config.modules.system;

  normalUsers = lib.filter (u: (u.isNormalUser or false)) (lib.attrValues config.users.users);


  # Import GPG keys and configure git signing for a specific user
  mkImportService =
    u:
    let
      uName = u.name;
      script = pkgs.writeShellScript "gpg-import-${uName}" ''
        set -euo pipefail

        PUB="${config.sops.secrets.gpg_public.path}"
        PRIV="${config.sops.secrets.gpg_private.path}"
        OT="${config.sops.secrets.gpg_ownertrust.path}"

        # Exit if secrets are not available
        if [ ! -f "$PUB" ] || [ ! -f "$PRIV" ]; then
          exit 0
        fi

        export GNUPGHOME="$HOME/.gnupg"
        mkdir -p "$GNUPGHOME"
        chmod 700 "$GNUPGHOME"

        # Extract fingerprint from public key
        FPR="$(gpg --batch --import-options show-only --with-colons --import "$PUB" \
              | awk -F: '/^fpr:/{print $10; exit}')"

        # Import keys if not already present
        if ! gpg --batch --list-secret-keys "$FPR" >/dev/null 2>&1; then
          gpg --batch --yes --import "$PUB"
          gpg --batch --yes --import "$PRIV"
        fi

        # Import ownertrust if defined
        if [ -f "$OT" ]; then
          gpg --batch --yes --import-ownertrust "$OT" || true
        fi
      '';
    in
    {
      description = "Import shared GPG key & enable Git signing for ${uName}";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "home-manager-${uName}.service"
      ];
      requires = [ "home-manager-${uName}.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = uName;
        Environment = "PATH=${
          lib.makeBinPath [
            pkgs.gnupg
            pkgs.coreutils
            pkgs.gawk
          ]
        }";
        ExecStart = "${script}";
      };
    };

in
{
  options.crypto.gpg.enable = lib.mkEnableOption "Auto-import sops-managed GPG keypair and enable Git commit/tag signing";

  config = lib.mkIf cfg.enable {
    # Define sops secrets for GPG
    sops.secrets.gpg_public = {
      owner = sysCfg.mainUser;
      mode = "0400";
    };
    sops.secrets.gpg_private = {
      owner = sysCfg.mainUser;
      mode = "0400";
    };
    sops.secrets.gpg_ownertrust = {
      owner = sysCfg.mainUser;
      mode = "0400";
    };

    environment.systemPackages = with pkgs; [
      gnupg
      git
      pinentry-curses
    ];

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = false;
      pinentryPackage = pkgs.pinentry-curses;
      settings = {
        default-cache-ttl = 3600;
        max-cache-ttl = 7200;
      };
    };

    # Ensure ~/.gnupg exists with correct permissions
    systemd.tmpfiles.rules = lib.flatten (
      map (u: [ "d /home/${u.name}/.gnupg 0700 ${u.name} ${u.group or "users"} -"]) normalUsers
    );

    systemd.services = lib.listToAttrs (
      map (u: {
        name = "gpg-import-${u.name}";
        value = mkImportService u;
      }) normalUsers
    );
  };
}

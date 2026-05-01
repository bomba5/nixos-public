# Module: modules/services/intune.nix
# Purpose: Microsoft Intune + Identity Broker on NixOS.
# Trick: pulls `microsoft-identity-broker` + `intune-portal` from nixpkgs-unstable
#        (which has the current Ubuntu-Noble-aligned recipes) and wraps intune-portal
#        in a bind-mount that spoofs /etc/os-release as Ubuntu 24.04 LTS for the
#        duration of enrollment, so Intune's compliance reader sees "Ubuntu".
# Credit: Niels de Koeijer <github.com/nielsdekoeijer/host> common/intune/intune.nix.
# Note:   stable nixpkgs 25.11 still ships microsoft-identity-broker 2.0.1 whose
#         build-phase expects jars that no longer exist in the 3.0.1 .deb. Using
#         unstable's 3.0.1 recipe avoids the `rm: jnr-posix-3.1.4.jar: No such file`
#         build failure. The flake already exposes `unstable` as a specialArg.
# Usage:  Import from hosts needing corporate-managed Intune enrollment.
#         No option — importing this file enables the stack unconditionally.
{ config, lib, pkgs, unstable, ... }:

let
  # GStreamer plugin path: WebKit2GTK needs `appsink` from gst-plugins-base
  # to render the AAD email/password sign-in flow. Without it the embedded
  # web view fails silently with `GStreamer element appsink not found` and
  # MSAL drops to errorCode 1001 right after the email is entered.
  gstPluginPath = lib.makeSearchPath "lib/gstreamer-1.0" [
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.gst_all_1.gst-plugins-bad
    pkgs.gst_all_1.gst-libav
  ];

  # Wrapper: spoofs /etc/os-release as Ubuntu 24.04 LTS for the duration of
  # intune-portal execution, then restores the real file via trap on exit.
  intune-portal-wrapped = pkgs.writeShellScriptBin "intune-portal" ''
    set -e

    echo "==> Spoofing Ubuntu 24.04 in /etc/os-release..."
    FAKE_OS_RELEASE=$(mktemp)

    cat << 'EOF' > "$FAKE_OS_RELEASE"
    NAME="Ubuntu"
    VERSION="24.04 LTS (Noble Numbat)"
    ID=ubuntu
    ID_LIKE=debian
    PRETTY_NAME="Ubuntu 24.04 LTS"
    VERSION_ID="24.04"
    HOME_URL="https://www.ubuntu.com/"
    SUPPORT_URL="https://help.ubuntu.com/"
    BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
    PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
    VERSION_CODENAME=noble
    UBUNTU_CODENAME=noble
    EOF

    trap 'echo "==> Restoring original /etc/os-release..."; sudo umount /etc/os-release; rm -f "$FAKE_OS_RELEASE"' EXIT

    sudo mount --bind "$FAKE_OS_RELEASE" /etc/os-release

    export GIO_EXTRA_MODULES="${pkgs.glib-networking}/lib/gio/modules"
    export GST_PLUGIN_SYSTEM_PATH_1_0="${gstPluginPath}"
    export SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
    export SSL_CERT_DIR="/etc/ssl/certs"
    export WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS="1"
    export WEBKIT_DISABLE_DMABUF_RENDERER="1"
    export GDK_BACKEND=x11
    export WEBKIT_DISABLE_COMPOSITING_MODE="1"
    export LIBGL_ALWAYS_SOFTWARE="1"
    export MSAL_ALLOW_PII="true"
    export MSAL_LOG_LEVEL="4"

    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all

    echo "==> Starting Intune Portal..."
    # Intentionally NOT using exec so the EXIT trap can fire afterwards.
    ${pkgs.intune-portal}/bin/intune-portal
  '';
in
{
  services.intune.enable = true;
  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;

  systemd.services.microsoft-identity-device-broker.environment = {
    GIO_EXTRA_MODULES = "${pkgs.glib-networking}/lib/gio/modules";
    GST_PLUGIN_SYSTEM_PATH_1_0 = gstPluginPath;
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    SSL_CERT_DIR = "/etc/ssl/certs";
    WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS = "1";
    MSAL_ALLOW_PII = "true";
    MSAL_LOG_LEVEL = "4";
    GDK_BACKEND = "x11";
    WEBKIT_DISABLE_COMPOSITING_MODE = "1";
    LIBGL_ALWAYS_SOFTWARE = "1";
  };

  # Note: no user-level systemd service exists for microsoft-identity-broker —
  # the package only ships the system-level microsoft-identity-device-broker
  # (dbus-activated). Setting environment on a nonexistent user unit creates
  # an invalid drop-in (no ExecStart) that fails to load. The runtime env vars
  # needed by the WebKitGTK sign-in flow are already exported by the
  # intune-portal-wrapped script above.

  environment.systemPackages = [
    intune-portal-wrapped
    pkgs.glib-networking
    pkgs.seahorse
    pkgs.microsoft-edge
  ];

  # Pull the current microsoft-identity-broker + intune-portal recipes from
  # nixpkgs-unstable (stable 25.11 is stuck on 2.0.1 / old intune-portal).
  nixpkgs.overlays = [
    (final: prev: {
      microsoft-identity-broker = unstable.microsoft-identity-broker;
      intune-portal = unstable.intune-portal;
    })
  ];

  # Microsoft packages are unfree. Allow only the specific ones this module needs.
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "intune-portal"
      "microsoft-identity-broker"
      "microsoft-edge"
      "microsoft-edge-stable"
    ];
}

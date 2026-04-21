# Module: modules/desktop/gui-server.nix
# Purpose: Lightweight GUI/display manager setup for server-like deployments needing auto-login.
# Options: No custom options; sets X11/GDM with auto-login for user bomba by default.
# Usage: Import in hosts that require a simple graphical session on boot without full desktop profile.
{
  services.xserver.enable = true;

  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "bomba";
    };
  };

  services.xserver.displayManager = {
    gdm = {
      enable = true;
      wayland = true;
    };
  };
}

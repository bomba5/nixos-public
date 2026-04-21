# Module: modules/services/ssh.nix
# Purpose: Enable OpenSSH server.
# Options: No custom options.
# Usage: Import anywhere SSH access is required (included by base profile).
{
  services.openssh.enable = true;
}

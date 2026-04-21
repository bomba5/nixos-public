# Module: modules/profiles/base.nix
# Purpose: Aggregate profile for core system pieces shared by all hosts (shell, editor, ssh, logging, docker).
# Options: No new options; pulls in modules that rely on modules.system.* from core.nix.
# Usage: Import in host configs or other profiles to inherit baseline services and tooling.
{ config, pkgs, ... }:

{
  imports = [
    ../core.nix
    ../shell/zsh.nix
    ../shell/tmux.nix
    ../editors/neovim.nix
    ../services/ssh.nix
    ../crypto/gpg.nix
    ../logging/rsyslog.nix
    ../virtualisation/docker.nix
    ../network/waypipe.nix
  ];
}

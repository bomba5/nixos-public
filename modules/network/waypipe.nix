# Module: modules/network/waypipe.nix
# Purpose: waypipe — remote a Wayland application over SSH with compression + damage tracking.
# Usage: `waypipe ssh user@host <app>`. Primary use-case here is accessing SSO-bound work apps
#        on a corporate-managed host from a personal one. Included in base profile so every
#        host has both the client (to receive) and the server (to forward) halves.
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.waypipe ];
}

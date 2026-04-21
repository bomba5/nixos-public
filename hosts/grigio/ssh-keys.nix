{ config, pkgs, lib, ... }:

let
  sysCfg = config.modules.system;
in
{
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.secrets."ssh_id_ed25519_grigio" = {
    owner = sysCfg.mainUser;
    path = "/home/${sysCfg.mainUser}/.ssh/id_ed25519";
    mode = "0600";
  };
  sops.secrets."ssh_id_ed25519_grigio_pub" = {
    owner = sysCfg.mainUser;
    path = "/home/${sysCfg.mainUser}/.ssh/id_ed25519.pub";
    mode = "0644";
  };
}

{ config, ... }:

let
  sysCfg = config.modules.system;
in
{
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.secrets."ssh_id_ed25519_ghibli" = {
    owner = sysCfg.mainUser;
    path = "/home/${sysCfg.mainUser}/.ssh/id_ed25519";
    mode = "0600";
  };
  sops.secrets."ssh_id_ed25519_ghibli_pub" = {
    owner = sysCfg.mainUser;
    path = "/home/${sysCfg.mainUser}/.ssh/id_ed25519.pub";
    mode = "0644";
  };
}

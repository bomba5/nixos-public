{ pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    kas
    uv
  ];
}

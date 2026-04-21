# Task shortcuts for managing the NixOS flake and secrets.

build HOSTNAME:
  nixos-rebuild build --flake .#{{HOSTNAME}}

switch HOSTNAME:
  nixos-rebuild switch --flake .#{{HOSTNAME}}

up HOSTNAME:
  nixos-rebuild switch --upgrade --flake .#{{HOSTNAME}}

update:
  nix flake update

edit-secrets:
  sops secrets/secrets.yaml

format:
  nixpkgs-fmt .

clean:
  sudo nix-collect-garbage -d

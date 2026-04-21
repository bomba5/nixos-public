{
  description = "Modular NixOS flake — multi-host, profile-based, sops-integrated, home-manager-wired.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      unstable,
      sops-nix,
      ...
    }:
    let
      mkHost =
        hostname:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/${hostname}/configuration.nix
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
          ];
          specialArgs = {
            # Re-import unstable with a narrow allowUnfreePredicate so we can pull
            # specific proprietary packages (Microsoft Intune stack, Edge) from
            # unstable without blanket-enabling all unfree packages system-wide.
            unstable = import unstable {
              system = "x86_64-linux";
              config.allowUnfreePredicate =
                pkg:
                builtins.elem (nixpkgs.lib.getName pkg) [
                  "intune-portal"
                  "microsoft-identity-broker"
                  "microsoft-edge"
                  "microsoft-edge-stable"
                ];
            };
            # Pass flake-specific arguments, e.g. self for dotfile paths
            flake-self = self;
          };
        };
    in
    {
      nixosConfigurations = {
        karaburan = mkHost "karaburan";
        ghibli = mkHost "ghibli";
        grigio = mkHost "grigio";
        gremo = mkHost "gremo";
      };
    };
}

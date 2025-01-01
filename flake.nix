{
  description = "Infrastructure.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, agenix, deploy-rs, ... }@attrs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      deployPkgs = import nixpkgs {
        inherit system;
        overlays = [
          deploy-rs.overlay
          (self: super: {
            deploy-rs = {
              inherit (pkgs) deploy-rs;
              lib = super.deploy-rs.lib;
            };
          })
        ];
      };
      meta = builtins.mapAttrs (key: value:
        let metaPath = ./systems/${key}/meta.nix;
        in if builtins.pathExists metaPath then import metaPath else { })
        (builtins.readDir ./systems);
    in {
      nixosConfigurations = (builtins.mapAttrs (key: value:
        (nixpkgs.lib.nixosSystem {
          system = meta.${key}.system or "x86_64-linux";
          specialArgs = attrs;
          modules = [
            ./modules
            ./roles
            ./systems/${key}/default.nix
            ./systems/${key}/hardware.nix

            { networking.hostName = pkgs.lib.mkDefault key; }
          ];
        })) (builtins.readDir ./systems));

      deploy.nodes = builtins.mapAttrs (key: value:
        let
          additional = pkgs.lib.filterAttrs (name: value: value != null) {
            sshUser = meta.${key}.deploy_user or null;
            sshOpts = meta.${key}.deploy_opts or null;
          };
        in {
          hostname = meta.${key}.deploy_addr or "${key}.lo.madloba.org";
          profiles.system = {
            user = "root";
            path = deployPkgs.deploy-rs.lib.activate.nixos value;
          } // additional;
        }) self.nixosConfigurations;

      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      overlays.default = final: prev: (import ./overlay.nix final attrs);
    } // flake-utils.lib.eachSystem
    (with flake-utils.lib.system; [ x86_64-linux aarch64-linux aarch64-darwin ])
    (system:
      let
        pkgs = import nixpkgs { inherit system; };
        overlay = import ./overlay.nix pkgs attrs;
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            agenix.packages.${system}.default
            pkgs.nixfmt-classic
            pkgs.deploy-rs
          ];
        };

        legacyPackages = overlay // {
          iso = (nixpkgs.lib.nixosSystem {
            specialArgs = attrs;
            system = "x86_64-linux";
            modules = [ ./modules ./modules/iso.nix ];
          }).config.system.build.isoImage;
        };
      });
}

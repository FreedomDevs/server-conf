{
  description = "Mikinol NixOS config";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-stable";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.home-manager.follows = "home-manager";
    agenix.inputs.nixpkgs.follows = "nixpkgs-stable";
    agenix.inputs.darwin.follows = "";

    mikinol-nix.url = "github:mikinol/mikinol-nix-flake";
    mikinol-nix.inputs.nixpkgs.follows = "nixpkgs-stable";

    elysium-server-control-scripts-src = {
      url = "github:FreedomDevs/server-control-scripts";
      flake = false;
    };

    svc-gateway-src = {
      url = "github:FreedomDevs/svc-gateway";
      flake = false;
    };

    eMC-src = {
      url = "github:FreedomDevs/eMC";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs-stable,
    nixpkgs-unstable,
    home-manager,
    agenix,
    elysium-server-control-scripts-src,
    svc-gateway-src,
    eMC-src,
    mikinol-nix,
    ...
  }: let
    system = "x86_64-linux";

    mkSystem = device: arch: let
      pkgs = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;

        overlays = [
          (final: prev: {
            unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          })
          (final: prev: {
            agenix = agenix.packages.${system}.default;
          })
          (final: prev: {
            mikinol-nix = mikinol-nix.packages.${system};
          })

          (final: prev: {
            # Инициализируется после всего
            custom = final.callPackage ./pkgs.nix {
              elysium-server-control-scripts-src = elysium-server-control-scripts-src;
              svc-gateway-src = svc-gateway-src;
              eMC-src = eMC-src;
              arch = arch;
            };
          })
        ];
      };
    in
      nixpkgs-stable.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit device;};

        modules = [
          "${self}/configuration.nix"
          "${self}/servers/${device}/hardware-configuration.nix"
          agenix.nixosModules.default

          {
            nixpkgs.pkgs = pkgs;
            nixpkgs.hostPlatform = system;

            nix.registry.nixpkgs.flake = nixpkgs-stable;
            nix.registry.unstable.flake = nixpkgs-unstable;
            nix.registry.home-manager.flake = home-manager;
            nix.registry.mikinol-nix.flake = mikinol-nix;
            nix.nixPath = ["nixpkgs=${nixpkgs-stable}"];
          }
        ];
      };
  in {
    nixosConfigurations = {
      elysia-game = mkSystem "elysia-game" null;
    };
  };
}

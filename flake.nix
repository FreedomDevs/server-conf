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

    ecli-src = {
      url = "github:FreedomDevs/ECLI";
      flake = false;
    };

    hyperbox-src = {
      url = "git+https://github.com/mikinol/hyperbox?submodules=1";
      flake = false;
    };

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
    agenix,
    disko,
    ecli-src,
    hyperbox-src,
    elysium-server-control-scripts-src,
    svc-gateway-src,
    eMC-src,
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
            # Инициализируется после всего
            custom = final.callPackage ./pkgs.nix {
              ecli-src = ecli-src;
              hyperbox-src = hyperbox-src;
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
          {nixpkgs.pkgs = pkgs;}
          {nixpkgs.hostPlatform = system;}

          disko.nixosModules.disko

          "${self}/configuration.nix"
          "${self}/servers/${device}/hardware-configuration.nix"

          agenix.nixosModules.default
        ];
      };
  in {
    nixosConfigurations = {
      vm-server = mkSystem "vm-server" null;
      elysia-game = mkSystem "elysia-game" null;
    };
  };
}

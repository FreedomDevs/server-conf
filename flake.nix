{
  description = "Mikinol NixOS config";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-stable";

    ecli-src = {
      url = "github:FreedomDevs/ECLI";
      flake = false;
    };

    hyperbox-src = {
      url = "git+https://github.com/mikinol/hyperbox?submodules=1";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs-stable,
    nixpkgs-unstable,
    ecli-src,
    hyperbox-src,
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
            # Инициализируется после всего
            custom = final.callPackage ./pkgs.nix {
              ecli-src = ecli-src;
              hyperbox-src = hyperbox-src;
              arch = arch;
            };
          })
        ];
      };
    in
      nixpkgs-stable.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit device; };

        modules = [
          {nixpkgs.pkgs = pkgs;}
          {nixpkgs.hostPlatform = system;}

          "${self}/configuration.nix"
          "${self}/hardware-configuration/${device}.nix"
        ];
      };
  in {
    nixosConfigurations = {
      main-game-server = mkSystem "main-game-server" null;
    };
  };
}

{lib, modulesPath, ...}: {
  system.stateVersion = "26.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  networking = {
    useDHCP = false;

    interfaces.ens3 = {
      ipv4.addresses = [{
        address = "31.77.143.249";
        prefixLength = 32;
      }];

      ipv4.routes = [{
        address = "0.0.0.0";
        prefixLength = 0;
        via = "100.65.65.65";
        options = {
          onlink = "";
        };
      }];
    };

    nameservers = [ "8.8.8.8" "8.8.4.4" ];
  };
}

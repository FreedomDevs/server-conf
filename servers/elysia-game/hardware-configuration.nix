{lib, modulesPath, ...}: {
  system.stateVersion = "26.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };

  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  networking = {
    useDHCP = false;
    hostName = "elysia-game";

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

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };
  swapDevices = [ {
    device = "/swapfile";
    size = 2 * 1024;
    priority = 10;
  } ];

  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "btrfs";
    options = ["subvol=root" "compress=zstd:3" "noatime" "discard=async"];
  };
  fileSystems."/home" = {
    device = "/dev/vda1";
    fsType = "btrfs";
    options = ["subvol=home" "compress=zstd:3" "noatime" "discard=async"];
  };
  fileSystems."/nix" = {
    device = "/dev/vda1";
    fsType = "btrfs";
    options = ["subvol=nix" "compress=zstd:9" "noatime" "discard=async"];
  };
}

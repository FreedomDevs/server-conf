{pkgs, ...}: let
  quotas = ''
    ${pkgs.btrfs-progs}/bin/btrfs qgroup limit 50M /home/game-server-1 || true
  '';
in {
  system.stateVersion = "26.05";

  services.autossh.sessions = [
    {
      name = "ssh-reverse-tunnel";
      user = "mikinol";

      extraArguments = "-N -R 2022:localhost:22 -o StrictHostKeyChecking=no mikinol@192.168.2.3";
    }
    {
      name = "http-reverse-tunnel";
      user = "mikinol";

      extraArguments = "-N -R 2080:localhost:80 -o StrictHostKeyChecking=no mikinol@192.168.2.3";
    }
    {
      name = "https-reverse-tunnel";
      user = "mikinol";

      extraArguments = "-N -R 2443:localhost:443 -o StrictHostKeyChecking=no mikinol@192.168.2.3";
    }
  ];

  systemd.services.enable-btrfs-quotas = {
    description = "Force Enable Btrfs quotas on /";

    wantedBy = ["local-fs.target"];
    after = ["local-fs.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      ${pkgs.btrfs-progs}/bin/btrfs quota enable /

      if sudo btrfs subvolume show /home >/dev/null 2>&1; then
        echo "Это subvolume!"
      else
        rm -rf /home
        systemd-tmpfiles --create
      fi

      USER_SSH_DIR="/home/mikinol/.ssh"
      TARGET_KEY="$USER_SSH_DIR/id_ed25519"

      if [ ! -d "$USER_SSH_DIR" ]; then
        mkdir -p "$USER_SSH_DIR"
        chmod 700 "$USER_SSH_DIR"
        chown mikinol:users "$USER_SSH_DIR"
      fi

      cp ${/home/mikinol/projects/elysium/server-conf/ssh_keys/id_ed25519} "$TARGET_KEY"

      chmod 600 "$TARGET_KEY"
      chown mikinol:users "$TARGET_KEY"

      ${pkgs.btrfs-progs}/bin/btrfs qgroup assign /home/game-server-1/backups /home/game-server-1 /

      ${quotas}
    '';
  };

  system.activationScripts.btrfs-limits.text = quotas;

  virtualisation.vmVariant = {
    virtualisation.diskSize = 2048;
    virtualisation.useDefaultFilesystems = false;
    boot.initrd.supportedFilesystems = ["btrfs"];
    virtualisation.fileSystems."/" = {
      device = "/dev/vda";
      autoFormat = true;
      fsType = "btrfs";
    };
  };
}

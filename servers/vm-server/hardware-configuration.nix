{pkgs, ...}: let
  quotas = ''
    ${pkgs.btrfs-progs}/bin/btrfs qgroup limit 60M 1/1 || true
    ${pkgs.btrfs-progs}/bin/btrfs qgroup limit 50M 1/2 || true
  '';
in {
  system.stateVersion = "26.05";

  services.autossh.sessions = [
    {
      name = "reverse-tunnel";
      user = "mikinol";
      extraArguments = "-N -R 2022:localhost:22 -R 2080:localhost:80 -R 2443:localhost:443 -o StrictHostKeyChecking=no mikinol@192.168.2.2";
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
      echo 1
      ${pkgs.btrfs-progs}/bin/btrfs quota enable / || true

      echo 2
      if ${pkgs.btrfs-progs}/bin/btrfs subvolume show /home >/dev/null 2>&1; then
        echo "Это subvolume!"
        exit 0
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

      PATH_HOME="/home"
      PATH_GAME="/home/game-server-1"
      PATH_BACKUPS="/home/game-server-1/backups"

      # Получаем ID сабволюмов
      ID_HOME=$(${pkgs.btrfs-progs}/bin/btrfs subvolume show "$PATH_HOME" | ${pkgs.gawk}/bin/awk '/Subvolume ID:/ {print $3}')
      ID_GAME=$(${pkgs.btrfs-progs}/bin/btrfs subvolume show "$PATH_GAME" | ${pkgs.gawk}/bin/awk '/Subvolume ID:/ {print $3}')
      ID_BACKUPS=$(${pkgs.btrfs-progs}/bin/btrfs subvolume show "$PATH_BACKUPS" | ${pkgs.gawk}/bin/awk '/Subvolume ID:/ {print $3}')

      # Создаем группы (игнорируем ошибку, если уже созданы)
      ${pkgs.btrfs-progs}/bin/btrfs qgroup create 1/1 "$PATH_HOME"
      ${pkgs.btrfs-progs}/bin/btrfs qgroup create 1/2 "$PATH_HOME"

      # 1. Группа 1/1: объединяет сервер и бэкапы
      ${pkgs.btrfs-progs}/bin/btrfs qgroup assign "0/$ID_GAME" 1/1 "$PATH_HOME"
      ${pkgs.btrfs-progs}/bin/btrfs qgroup assign "0/$ID_BACKUPS" 1/1 "$PATH_HOME"

      # 2. Группа 1/2: объединяет ВСЕ ТРИ сабволюма (сам /home + сервер + бэкапы)
      ${pkgs.btrfs-progs}/bin/btrfs qgroup assign "0/$ID_HOME" 1/2 "$PATH_HOME"
      ${pkgs.btrfs-progs}/bin/btrfs qgroup assign "0/$ID_GAME" 1/2 "$PATH_HOME"
      ${pkgs.btrfs-progs}/bin/btrfs qgroup assign "0/$ID_BACKUPS" 1/2 "$PATH_HOME"

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

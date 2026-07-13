{...}: {
  system.activationScripts.copyMikinolSshKey = {
    text = ''
      USER_SSH_DIR="/home/mikinol/.ssh"
      TARGET_KEY="$USER_SSH_DIR/id_ed25519"

      if [ ! -d "$USER_SSH_DIR" ]; then
        mkdir -p "$USER_SSH_DIR"
        chmod 700 "$USER_SSH_DIR"
        chown mikinol:users "$USER_SSH_DIR"
      fi

      echo "Копирую SSH ключ из store в домашнюю папку..."
      cp ${/home/mikinol/projects/elysium/server-conf/ssh_keys/id_ed25519} "$TARGET_KEY"
      
      chmod 600 "$TARGET_KEY"
      chmod 600 "$TARGET_AUTH"
      chown mikinol:users "$TARGET_KEY"
    '';
  };
  services.autossh.sessions = [
    {
      name = "ssh-reverse-tunnel";
      user = "mikinol"; 
      
      # Аргументы для SSH:
      # -R 2022:localhost:22 означает: открыть на удаленном хосте порт 2022 
      #  и перенаправлять весь трафик с него на локальный порт 22 (внутрь виртуалки)
      # -N говорит не запускать удаленную оболочку (просто держать туннель)
      extraArguments = "-N -R 2022:localhost:22 -o StrictHostKeyChecking=no mikinol@192.168.2.2";
    }
  ];
}

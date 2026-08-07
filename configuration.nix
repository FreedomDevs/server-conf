{
  pkgs,
  device,
  ...
}: {
  imports = [
    ./services/services.nix
    ./tmpfiles.nix
  ];
  boot.initrd.systemd.emergencyAccess = true;

  users.groups.mc-admins = { gid = 1000; };
  users.groups.podman = { gid = 1001;};

  users.groups.web-access = { gid = 1002; }; # Даёт доступ к /var/www

  users.groups.proc-access = { gid = 1003; };

  systemd.services.remount-proc = {
    description = "Remount /proc with hidepid and custom GID on boot";
    
    # Запускаем только при загрузке системы (после того как монтируются базовые ФС)
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true; # Чтобы systemd считал службу успешно завершенной и не перезапускал
      ExecStart = "${pkgs.util-linux}/bin/mount -o remount,hidepid=invisible,gid=1003 /proc";
    };
  };

  users.users.mikinol = {
    isNormalUser = true;
    initialPassword = "123";
    extraGroups = ["wheel" "podman" "proc-access"];

    uid = 1001;

    createHome = false;
    home = "/home/mikinol";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII957WmPPCOJTsKjHS6dJ4OT+SObewPbOH1BK537mgsQ" # Мой ключ, для меня
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPngKu24f4aaEROijzY/YSpBBJsLLIfBq+0ri7HamSQA sm44aksdmiki13877kfh@gmail.com"
    ];
  };

  /*users.users.game-server-1 = {
    isNormalUser = true;
    #hashedPassword = "*";
    initialPassword = "123";
    extraGroups = ["mc-admins"];

    uid = 1100;

    createHome = false;
    home = "/home/game-server-1";

    packages = with pkgs; [
      openjdk21_headless
      custom.elysium-server-control-scripts
    ];

    openssh.authorizedKeys.keys = [
      # Тут будут ключи админов
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII957WmPPCOJTsKjHS6dJ4OT+SObewPbOH1BK537mgsQ"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPngKu24f4aaEROijzY/YSpBBJsLLIfBq+0ri7HamSQA sm44aksdmiki13877kfh@gmail.com"
    ];
  };*/

  /*security.pam.loginLimits = [
    { domain = "game-server-1"; item = "nproc"; type = "hard"; value = "200"; }
    { domain = "game-server-1"; item = "nofile"; type = "soft"; value = "1024"; }
    { domain = "game-server-1"; item = "nofile"; type = "hard"; value = "4096"; }
    { domain = "game-server-1"; item = "core"; type = "hard"; value = "0"; }
  ];

  systemd.slices."user-1100" = {
    sliceConfig = {
      MemoryLow="2G";
      MemoryHigh = "4.5G";
      MemoryMax = "5G";
      MemorySwapMax = "2G";
      CPUQuota = "100%";

      SocketBindDeny="any";
      SocketBindAllow="10.0.2.15:3000-3010";

      IPAddressDeny="localhost 127.0.0.0/8 10.0.0.0/8 192.168.0.0/16 169.254.0.0/16";
      IPAddressAllow="any";

      TasksMax = 200;
    };
  };*/

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };
  systemd.sockets.podman.socketConfig = {
    SocketMode = "0660";
    SocketUser = "root";
    SocketGroup = "podman";
  };

  environment.extraInit = ''
    if id -nG | grep -q -E '\bpodman\b'; then
      export CONTAINER_HOST="unix:///run/podman/podman.sock"
      export DOCKER_HOST="unix:///run/podman/podman.sock"
    fi
  '';

  security.sudo = {
    enable = true;
    extraRules = [
      {
        groups = ["mc-admins"];
        commands = [
          {
            command = "${pkgs.custom.elysium-server-control-scripts}/internal/publish_resourcepack";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [22 80 443];

  /*age.identityPaths = [
    "/home/mikinol/.ssh/id_ed25519"
  ];
  age.secrets = {
    "resourcepack_namespace" = {
      file = ./servers/${device}/secrets/resourcepack_namespace.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };*/

  environment.systemPackages = with pkgs; [
    home-manager
    git
    custom.eMC
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
}

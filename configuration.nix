{
  pkgs,
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
  users.groups.admins = { gid = 1004; };

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
    extraGroups = ["wheel" "podman" "proc-access" "admins"];

    uid = 1001;

    createHome = false;
    home = "/home/mikinol";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII957WmPPCOJTsKjHS6dJ4OT+SObewPbOH1BK537mgsQ pc"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPngKu24f4aaEROijzY/YSpBBJsLLIfBq+0ri7HamSQA laptop"
    ];
  };

  users.users.foksik = {
    isNormalUser = true;
    initialPassword = "123";
    extraGroups = ["wheel" "podman" "proc-access" "admins"];

    uid = 1002;

    createHome = false;
    home = "/home/foksik";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJvj4GQR/TM/i1yZ3j8TTSJXZfOjOMY0zhAWen40+YPE foksik@nixos"
    ];
  };

  users.users.dead-cats = {
    isNormalUser = true;
    hashedPassword = "*";
    extraGroups = ["mc-admins"];

    uid = 1100;

    createHome = false;
    home = "/home/dead-cats";

    packages = with pkgs; [
      openjdk25_headless
      #custom.elysium-server-control-scripts
    ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKGl+3yT5NFC+w9AgFwTQCACD6gr+9vCyUvv8Em/2dSR ivanz@Magelan"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+jcHmUsK6+b+/y5mHPsep9UCaMDEtXQEc9rTNPM6Sm spectrich@DESKTOP-H5DJPAD"
    ];
  };

  users.users.forki = {
    isNormalUser = true;
    hashedPassword = "*";
    extraGroups = ["mc-admins"];

    uid = 1101;

    createHome = false;
    home = "/home/forki";


    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE88gLFnPEgMWTPkQO3OqJ5jQdE7bvl+p6VxIkWMMdXe forki@debian"
    ];
  };

  security.pam.loginLimits = [
    { domain = "dead-cats"; item = "nproc"; type = "hard"; value = "5000"; }
    { domain = "dead-cats"; item = "nofile"; type = "soft"; value = "1024"; }
    { domain = "dead-cats"; item = "nofile"; type = "hard"; value = "4096"; }

    { domain = "forki"; item = "nproc"; type = "hard"; value = "500"; }
    { domain = "forki"; item = "nofile"; type = "soft"; value = "1024"; }
    { domain = "forki"; item = "nofile"; type = "hard"; value = "4096"; }
  ];

  systemd.slices."user-1100" = {
    sliceConfig = {
      MemoryLow="2G";
      MemoryHigh = "4.6G";
      MemoryMax = "5.1G";
      MemorySwapMax = "2G";
      CPUQuota = "125%";

      SocketBindDeny="any";
      SocketBindAllow="3000-3999";

      RestrictNetworkInterfaces="ens3 lo";

      #IPAddressDeny = "any";

      TasksMax = 5000;
    };
  };
  systemd.slices."user-1101" = {
    sliceConfig = {
      MemoryHigh = "0.7G";
      MemoryMax = "1.0G";
      MemorySwapMax = "1G";
      CPUQuota = "5%";

      SocketBindDeny="any";
      SocketBindAllow="4000-4999";

      RestrictNetworkInterfaces="ens3 lo";

      #IPAddressDeny = "any";

      TasksMax = 500;
    };
  };

  networking.firewall.allowedTCPPorts = [22 80 443 25565];
  networking.firewall.allowedUDPPorts = [443];
  networking.firewall.allowedTCPPortRanges = [{ from = 3000; to = 3999; } { from = 4000; to = 4999; }];
  networking.firewall.allowedUDPPortRanges = [{ from = 3000; to = 3999; } { from = 4000; to = 4999; }];

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

  age.identityPaths = [
    "/root/.ssh/id_ed25519"
  ];
  age.secrets = {
    "elysiac.fun.key" = {
      file = ./files/certs/elysiac.fun.key;
      owner = "nginx";
      group = "0";
      mode = "0400";
    };
    "elysia-game-ech_elysiac.fun.pem" = {
      file = ./files/certs/elysia-game-ech_elysiac.fun.pem;
      owner = "nginx";
      group = "0";
      mode = "0400";
    };
  };

  environment.systemPackages = with pkgs; [
    home-manager
    git
    #custom.eMC
  ];

  users.motd = builtins.replaceStrings [ "\\033" ] [ (builtins.fromJSON "\"\\u001b\"") ] (builtins.readFile ./files/banner.txt);
  environment.interactiveShellInit = ''
    if [ -n "$TERM" ] && ! ${pkgs.ncurses}/bin/infocmp "$TERM" >/dev/null 2>&1; then
      export TERM="xterm-256color"
    fi
  '';

  boot.kernel.sysctl = {
    "net.ipv4.tcp_fastopen" = 3;
    "kernel.pid_max" = 999999;
  };

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = ["nix-command" "flakes"];
    stalled-download-timeout = 10;
    connect-timeout = 5;

    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="];
  };
}

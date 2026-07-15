{
  pkgs,
  device,
  ...
}: {
  imports = [
    ./services/services.nix
    ./vmconfig.nix
    ./tmpfiles.nix
  ];

  users.groups.mc-admins = {};
  users.groups.podman = {};

  users.groups.web-access = {}; # Даёт доступ к /var/www

  users.users.mikinol = {
    isNormalUser = true;
    initialPassword = "123";
    extraGroups = ["wheel" "podman"];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII957WmPPCOJTsKjHS6dJ4OT+SObewPbOH1BK537mgsQ" # Мой ключ, для меня
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPngKu24f4aaEROijzY/YSpBBJsLLIfBq+0ri7HamSQA" # Ноут
    ];
  };

  users.users.game-server-1 = {
    isNormalUser = true;
    hashedPassword = "*";
    extraGroups = ["mc-admins"];

    packages = with pkgs; [
      openjdk21_headless
      custom.elysium-server-control-scripts
    ];

    openssh.authorizedKeys.keys = [
      # Тут будут ключи админов
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII957WmPPCOJTsKjHS6dJ4OT+SObewPbOH1BK537mgsQ"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPngKu24f4aaEROijzY/YSpBBJsLLIfBq+0ri7HamSQA"
    ];
  };

  security.pam.loginLimits = [
    {
      domain = "game-server-1";
      type = "hard";
      item = "nproc";
      value = "128";
    }
    {
      domain = "game-server-1";
      type = "hard";
      item = "nofile";
      value = "1024";
    }
  ];
  systemd.slices."user-1000" = {
    sliceConfig = {
      MemoryHigh = "6G";
      MemoryMax = "8G";
      MemorySwapMax = "2G";
    };
  };

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

  networking.firewall.allowedTCPPorts = [22 80 443];

  age.identityPaths = [
    "/home/mikinol/.ssh/id_ed25519"
  ];
  age.secrets = {
    "resourcepack_namespace" = {
      file = ./servers/${device}/secrets/resourcepack_namespace.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  environment.systemPackages = with pkgs; [
    home-manager
    git
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
}

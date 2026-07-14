{pkgs, ...}:{
  imports = [
    ./services/services.nix
    ./vmconfig.nix
  ];

  users.groups.mc-admins = {};
  users.groups.podman = {};

  users.users.mikinol = {
    isNormalUser = true;
    initialPassword = "123";
    extraGroups = ["wheel" "podman"];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII957WmPPCOJTsKjHS6dJ4OT+SObewPbOH1BK537mgsQ sm44aksdmiki13877kfh@gmail.com" # Мой ключ, для меня
    ];
  };

  users.users.game-server-1 = {
    isNormalUser = true;
    hashedPassword = "*";
    extraGroups = ["mc-admins"];

    openssh.authorizedKeys.keys = [ # Тут будут ключи админов
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII957WmPPCOJTsKjHS6dJ4OT+SObewPbOH1BK537mgsQ sm44aksdmiki13877kfh@gmail.com"
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

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  environment.systemPackages = with pkgs; [
    home-manager
    git
    openjdk21_headless
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
}

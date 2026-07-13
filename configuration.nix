{pkgs, ...}:{
  imports = [
    ./services/services.nix
    ./vmconfig.nix
  ];

  users.groups.mc-admins = {};

  users.users.mikinol = {
    isNormalUser = true;
    initialPassword = "123";
    extraGroups = ["wheel"];


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

  environment.systemPackages = with pkgs; [
    home-manager
    git
    openjdk21_headless
  ];

}

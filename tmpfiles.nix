{pkgs, ...}: let
  text = builtins.readFile ./html/resourcepacks_index.html;
  resourcepacksIndexHtml = pkgs.writeText "resourcepacks_index.html" text;
in {
  systemd.tmpfiles.rules = [
    "d /var/www 0710 root nginx"

    "d /var/www/resourcepacks 2750 root nginx"
    "L+ /var/www/resourcepacks/index.html - - - - ${resourcepacksIndexHtml}"

    "q /home/mikinol 0700 mikinol users"

    "q /home/game-server-1 0700 game-server-1 users"
    "d /home/game-server-1/server 0700 game-server-1 users"

    #"q /home/game-server-1/backups 0700 game-server-1 users"
  ];
}

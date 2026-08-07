{pkgs, ...}: let
  text = builtins.readFile ./html/resourcepacks_index.html;
  resourcepacksIndexHtml = pkgs.writeText "resourcepacks_index.html" text;
in {
  systemd.tmpfiles.rules = [
    "d /var/www 0710 root nginx"

    "d /var/www/resourcepacks 2750 root nginx"
    "L+ /var/www/resourcepacks/index.html - - - - ${resourcepacksIndexHtml}"
  ];
}

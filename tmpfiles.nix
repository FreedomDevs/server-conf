{...}: {
  systemd.tmpfiles.rules = [
    "d /var/www 0710 root nginx"

    "d /var/www/resourcepacks 2750 root nginx -"
  ];
}

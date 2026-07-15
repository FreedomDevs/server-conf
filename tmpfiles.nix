{...}: {
  systemd.tmpfiles.rules = [
    "d /var/www 0710 root nginx"

    "d /var/www/resourcepacks 2750 root nginx -"
  ];

  virtualisation.vmVariant = {
    # 1. Увеличиваем размер диска виртуалки (чтобы хватило на квоты и тесты)
    virtualisation.diskSize = 2048; # в Мегабайтах (2 ГБ)

    # 2. Переопределяем файловую систему по умолчанию на Btrfs
    virtualisation.fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      autoFormat = true;
      fsType = "btrfs"; # <- Вот тут магия!
    };
  };
}

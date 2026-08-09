{...}: {
  systemd.tmpfiles.rules = [
    "d /home 0010 0 users"
    "a /home - - - - user::---,user:nginx:--x,group::--x,group:admins:r-x,mask::r-x,other::---"

    "d /home/dead-cats 0700 dead-cats users"
    "a /home/dead-cats - - - - user::rwx,user:nginx:--x,group::---,mask::--x,other::---"

    "d /home/dead-cats/public 2750 dead-cats nginx"
    "d /home/dead-cats/public/resourcepacks 2750 dead-cats nginx"
    "Z /home/dead-cats/public 2750 dead-cats nginx"
  ];
}

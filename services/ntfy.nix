{...}: {
  systemd.services.ntfy-sh.serviceConfig.ReadWritePaths = [ "/var/sockets/ntfy" ];

  services.ntfy-sh = {
    enable = true;
    user = "ntfy-sh";
    group = "ntfy-sh";

    settings = {
      base-url = "https://ntfy.elysiac.fun";
      listen-unix = "/var/sockets/ntfy/sock";
      listen-unix-mode = 0660;
      behind-proxy = true;
      auth-default-access = "deny-all";
    };
  };
}

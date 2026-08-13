{pkgs}: let
  defaultListen = [
    {
      addr = "[::]";
      port = 443;
      ssl = true;
    }
    {
      addr = "[::]";
      port = 443;
      extraParameters = ["quic"];
    }
  ];

  internalHtml =
    pkgs.runCommand "internal_html" {
      nativeBuildInputs = [pkgs.brotli];
    } ''
      mkdir -p $out

      sed -e 's/    //g' -e 's/: /:/g' -e 's/ {/{/g' < ${../../files/resourcepacks_index.html} | tr -d '\n' > $out/resourcepacks_index.html
      brotli -q 11 --keep $out/resourcepacks_index.html
    '';
  internalHtmlETag = "\"${builtins.substring 0 32 (baseNameOf (toString internalHtml))}\"";
in {
  "default" = {
    default = true;
    listen = [
      {
        addr = "[::]";
        port = 80;
        extraParameters = ["fastopen=64" "ipv6only=off" "default_server"];
      }
      {
        addr = "[::]";
        port = 443;
        ssl = true;
        extraParameters = ["fastopen=64" "ipv6only=off" "default_server"];
      }
      {
        addr = "[::]";
        port = 443;
        extraParameters = ["quic" "ipv6only=off" "default_server"];
      }
    ];

    root = "${pkgs.emptyDirectory}";
    rejectSSL = true;
    locations."/".return = 444;
  };

  "http" = {
    listen = [
      {
        addr = "[::]";
        port = 80;
      }
    ];

    serverName = "elysiac.fun";
    serverAliases = ["*.elysiac.fun" "dead-cats.su" "*.dead-cats.su" "runa-trip.fun" "*.runa-trip.fun"];
    extraConfig = ''more_clear_headers "date";more_clear_headers "server";'';
    locations."/".return = "301 https://$host$request_uri";
  };

  "elysiac.fun" = {
    listen = defaultListen;
    onlySSL = true;
    sslCertificate = "${../../files/certs/elysiac.fun.crt}";
    sslCertificateKey = "/run/agenix/elysiac.fun.key";

    locations."/" = {
      root = "/var/www/www-main";
      tryFiles = "$uri $uri/ =404";
      extraConfig = "add_header Cache-Control \"public, max-age=120, stale-if-error=31536000\";";
    };
    extraConfig = "ssl_ech_file /run/agenix/elysia-game-ech_elysiac.fun.pem;";
  };
  "admin.elysiac.fun" = {
    listen = defaultListen;
    onlySSL = true;
    sslCertificate = "${../../files/certs/elysiac.fun.crt}";
    sslCertificateKey = "/run/agenix/elysiac.fun.key";

    locations."/" = {
      root = "/var/www/www-admin";
      tryFiles = "$uri $uri/ =404";
      extraConfig = "add_header Cache-Control \"public, max-age=120, stale-if-error=31536000\";";
    };
    extraConfig = "ssl_ech_file /run/agenix/elysia-game-ech_elysiac.fun.pem;";
  };

  "resourcepacks.elysiac.fun" = {
    listen = defaultListen;
    onlySSL = true;
    sslCertificate = "${../../files/certs/elysiac.fun.crt}";
    sslCertificateKey = "/run/agenix/elysiac.fun.key";

    locations."/".return = 404;
    locations."= /" = {
      root = "/";
      tryFiles = "${internalHtml}/resourcepacks_index.html =404";
      extraConfig = ''
        more_clear_headers -s 304 "Content-Type";
        more_clear_headers "last-modified";
        more_clear_headers "server";
        if_modified_since off;
        etag off;

        brotli_static on;

        more_set_headers 'etag: ${internalHtmlETag}';
        if ($http_if_none_match ~ '${internalHtmlETag}') {
          return 304;
        }
      '';
    };
    locations."~ ^/([^/]+)/([^/]+)$" = {
      alias = "/home/$1/public/resourcepacks/$2";
      extraConfig = ''
        more_clear_headers "last-modified";
        more_clear_headers "server";

        disable_symlinks on from=/home/$1;
        error_page 403 = 404;
      '';
    };
    extraConfig = "ssl_ech_file /run/agenix/elysia-game-ech_elysiac.fun.pem;";
  };

  "ntfy.elysiac.fun" = {
    listen = defaultListen;
    onlySSL = true;
    sslCertificate = "${../../files/certs/elysiac.fun.crt}";
    sslCertificateKey = "/run/agenix/elysiac.fun.key";

    locations."/" = {
      proxyPass = "http://unix:/var/sockets/ntfy/sock";
      proxyWebsockets = true;

      extraConfig = ''
        more_clear_headers "server";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Authorization $http_authorization;

        proxy_read_timeout 1d;
        proxy_send_timeout 1d;
      '';
    };
    extraConfig = "ssl_ech_file /run/agenix/elysia-game-ech_elysiac.fun.pem;";
  };
}

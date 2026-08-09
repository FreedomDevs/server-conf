{pkgs, lib, ...}: let
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

  /*
{
      addr = "[::1]";
      port = 81;
      extraParameters = ["fastopen=64"];
    }
*/

    resourcepacksIndexHtml = pkgs.writeText "resourcepacks_index.html" (builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile ../files/resourcepacks_index.html));

  internalHtml = pkgs.runCommand "internal_html" {
    nativeBuildInputs = [ pkgs.brotli ];
  } ''
    mkdir -p $out

    sed -e 's/    //g' -e 's/\n//g' -e 's/: /:/g' -e 's/ {/{/g' < ${../files/resourcepacks_index.html} > $out/resourcepacks_index.html
    brotli -q 11 --keep $out/resourcepacks_index.html
  '';
  internalHtmlETag = "\"${builtins.substring 0 32 (baseNameOf (toString resourcepacksIndexHtml))}\"";

  extraLuaPackages = [
    pkgs.unstable.luajitPackages.lua-resty-jwt
    pkgs.unstable.luajitPackages.lua-resty-http
    pkgs.unstable.luajitPackages.lua-resty-lrucache
    pkgs.unstable.luajitPackages.lua-resty-openssl
    pkgs.unstable.luajitPackages.cjson
    pkgs.custom.svc-gateway.lua-resty-websocket
  ];

  luaPath = lib.concatMapStringsSep ";" (p: "${p}/share/lua/5.1/?.lua;${p}/share/lua/5.1/?/init.lua") extraLuaPackages;
  luaCPath = lib.concatMapStringsSep ";" (p: "${p}/lib/lua/5.1/?.so") extraLuaPackages;
in {
  systemd.services.nginx.serviceConfig = {
    ProtectHome = "no";
  };

  services.nginx = {
    enable = true;
    package = pkgs.unstable.openresty;
    user = "nginx";
    group = "nginx";

    additionalModules = with pkgs.unstable.nginxModules; [
      brotli
    ];

    appendHttpConfig = ''
      lua_package_path ";;${luaPath};;";
      lua_package_cpath ";;${luaCPath};;";
    '';

    virtualHosts."default" = {
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
      locations."/" = {
        extraConfig = "return 444;";
      };
    };

    virtualHosts."http" = {
      listen = [
        {
          addr = "[::]";
          port = 80;
        }
      ];

      serverName = "elysiac.fun";
      serverAliases = ["*.elysiac.fun" "dead-cats.su" "*.dead-cats.su" "runa-trip.fun" "*.runa-trip.fun"];

      extraConfig = ''
        more_clear_headers "date";
        more_clear_headers "server";
        return 301 https://$host$request_uri;
      '';
    };

    virtualHosts."resourcepacks.elysiac.fun" = {
      listen = defaultListen;
      onlySSL = true;
      sslCertificate = "${../certs/elysiac.fun.crt}";
      sslCertificateKey = "/run/agenix/elysiac.fun.key";

      locations."/".extraConfig = "return 404;";
      locations."= /" = {
        root = "/";
        tryFiles = "${internalHtml}/resourcepacks_index.html =404";
        extraConfig = ''
          more_clear_headers "last-modified";
          more_clear_headers "date";
          more_clear_headers "server";
          if_modified_since off;
          etag off;

          brotli_static on;

          more_set_headers 'etag: ${internalHtmlETag}';
          if ($http_if_none_match = '${internalHtmlETag}') {
            return 304;
          }
        '';
      };
      locations."~ ^/([^/]+)/([^/]+)$" = {
        alias = "/home/$1/public/resourcepacks/$2";
        extraConfig = ''
          more_clear_headers "last-modified";
          more_clear_headers "date";
          more_clear_headers "server";

          disable_symlinks on from=/home/$1;
          error_page 403 = 404;
        '';
      };
    };
  };
}

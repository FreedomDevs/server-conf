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

  text = builtins.readFile ../files/resourcepacks_index.html;
  resourcepacksIndexHtml = pkgs.writeText "resourcepacks_index.html" text;

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
        return 301 https://$host$request_uri;
      '';
    };

    virtualHosts."resourcepacks.elysiac.fun" = {
      listen = defaultListen;
      onlySSL = true;
      sslCertificate = "${../certs/elysiac.fun.crt}";
      sslCertificateKey = "/run/agenix/elysiac.fun.key";

      locations."= /".tryFiles = "${resourcepacksIndexHtml} =404";
      locations."~ ^/([^/]+)/(.+)$".tryFiles = "/home/$1/public/resourcepacks/$2 =404";
    };
  };
}

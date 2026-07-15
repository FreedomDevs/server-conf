{pkgs, ...}: let
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

  test_cert = "${../cert/test.crt}";
  test_key = "${../cert/test.key}";
in {
  services.nginx = {
    package = pkgs.unstable.nginx;
    enable = true;

    additionalModules = with pkgs.nginxModules; [
      echo
      lua
      brotli
      moreheaders
    ];

    appendHttpConfig = ''
      lua_package_path "${pkgs.custom.svc-gateway.luaDependencies};";
    '';

    virtualHosts."default" = {
      default = true;
      listen = [
        {
          addr = "[::]";
          port = 80;
          extraParameters = ["fastopen=256" "ipv6only=off" "default_server"];
        }
        {
          addr = "[::]";
          port = 443;
          ssl = true;
          extraParameters = ["fastopen=256" "ipv6only=off" "default_server"];
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

      serverName = "test.lan";
      serverAliases = ["*.test.lan"];

      extraConfig = ''
        return 301 https://$host$request_uri;
      '';
    };

    virtualHosts."test.lan" = {
      listen = defaultListen;

      onlySSL = true;
      sslCertificate = test_cert;
      sslCertificateKey = test_key;
    };

    virtualHosts."resourcepacks.test.lan" = {
      listen = defaultListen;

      root = "/var/www/resourcepacks";

      onlySSL = true;
      sslCertificate = test_cert;
      sslCertificateKey = test_key;

      extraConfig = ''
        index index.html;
      '';
    };
  };
}

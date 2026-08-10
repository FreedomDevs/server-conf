{
  pkgs,
  lib,
  ...
}: let
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
    package = pkgs.unstable.openresty.override {openssl = pkgs.unstable.openssl_4_0;};
    user = "nginx";
    group = "nginx";

    additionalModules = with pkgs.unstable.nginxModules; [
      brotli
    ];

    appendHttpConfig = ''
      lua_package_path ";;${luaPath};;";
      lua_package_cpath ";;${luaCPath};;";
    '';

    virtualHosts = import ./nginx/virtualhosts.nix;
  };
}

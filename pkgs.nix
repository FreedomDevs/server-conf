{
  callPackage,
  stdenv,
  ecli-src,
  hyperbox-src,
  elysium-server-control-scripts-src,
  svc-gateway-src,
eMC-src,
  arch ? null,
}: let
  optimizedStdenv =
    if arch != null
    then
      stdenv.override {
        hostPlatform =
          stdenv.hostPlatform
          // {
            gcc.arch = arch;
          };
      }
    else stdenv;
in {
  ecli = callPackage ecli-src {stdenv = optimizedStdenv;};
  hyperbox = callPackage hyperbox-src {stdenv = optimizedStdenv;};
  elysium-server-control-scripts = callPackage elysium-server-control-scripts-src {};
  svc-gateway = callPackage svc-gateway-src {};
  eMC = callPackage eMC-src {stdenv = optimizedStdenv;};
}

{
  callPackage,
  unstable,
  stdenv,
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
  elysium-server-control-scripts = callPackage elysium-server-control-scripts-src {};
  svc-gateway = unstable.callPackage svc-gateway-src {};
  eMC = callPackage eMC-src {stdenv = optimizedStdenv;};
}

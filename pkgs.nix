{
  callPackage,
  stdenv,
  ecli-src,
  hyperbox-src,
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
}

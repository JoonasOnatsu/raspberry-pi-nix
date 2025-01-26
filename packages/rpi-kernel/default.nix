{
  stdenv,
  lib,
  callPackage,
  platforms,
  ...
}: let
  kernels =
    lib.foldlAttrs (
      acc: platform: attrs: let
        defConfig = attrs.defconfig;
        boardName = attrs.board;
      in
        if stdenv.system != attrs.system
        then acc
        else
          acc
          // {
            "${boardName}" = callPackage ./kernel.nix {inherit defConfig boardName;};
          }
    ) {}
    platforms;
in
  kernels

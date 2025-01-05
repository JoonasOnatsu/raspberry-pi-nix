{
  nixpkgs,
  lib ? nixpkgs.lib,
  ...
}:
# Attributes for each Raspberry Pi system.
# Use 'pkgsCross' from 'nixpkgs' if possible,
# to leverage binary caches. If not, define
# custom 'pkgs' for the platform.
# https://en.wikipedia.org/wiki/Raspberry_Pi#Specifications
rec {
  raspberryPi = {
    system = "armv6l-linux";
    board = "bcm2835";
    crossSystem =
      lib.systems.platforms.raspberrypi
      // {
        config = "armv6l-unknown-linux-gnueabihf";
      };
    #pkgsCross = pkgs.pkgsCross.raspberryPi;
  };
  raspberryPiZero = raspberryPi;
  raspberryPiZeroW = raspberryPi;
  raspberryPiZero2W = {
    system = "aarch64-linux";
    board = "bcm2710";
    crossSystem =
      lib.systems.platforms.aarch64-multiplatform
      // {
        config = "aarch64-unknown-linux-gnu";
      };
    #pkgsCross = pkgs.pkgsCross.aarch64-multiplatform;
  };
  raspberryPi2 = {
    system = "armv7l-linux";
    board = "bcm2836";
    crossSystem =
      lib.systems.platforms.raspberrypi2
      // {
        config = "armv7l-unknown-linux-gnueabihf";
      };
    #pkgsCross = pkgs.pkgsCross.armv7l-hf-multiplatform;
  };
  raspberryPi3 = {
    system = "aarch64-linux";
    board = "bcm2837";
    crossSystem =
      lib.systems.platforms.aarch64-multiplatform
      // {
        config = "aarch64-unknown-linux-gnu";
      };
    #pkgsCross = pkgs.pkgsCross.aarch64-multiplatform;
  };
  raspberryPi4 = {
    system = "aarch64-linux";
    board = "bcm2711";
    crossSystem =
      lib.systems.platforms.aarch64-multiplatform
      // {
        config = "aarch64-unknown-linux-gnu";
      };
    #pkgsCross = pkgs.pkgsCross.aarch64-multiplatform;
  };
}
#(lib.mapAttrs (
#  plat: cfg: {
#    config = cfg;
#    pkgsCross =
#      if builtins.hasAttr "pkgsCross" cfg
#      then cfg.pkgsCross
#      else mkCrossPkgs cfg;
#  }
#)
#rpiSystems)

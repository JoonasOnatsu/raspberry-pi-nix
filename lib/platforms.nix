args @ {
  nixpkgs,
  lib ? nixpkgs.lib,
  overlays ? [],
  nixpkgsConfig ? {
    allowUnsupportedSystem = true;
    allowUnfree = true;
  },
  localSystem ? {
    config = "x86_64-unknown-linux-gnu";
    system = "x86_64-linux";
  },
  ...
}:
# Attributes for each Raspberry Pi system.
# Use 'pkgsCross' from 'nixpkgs' if possible,
# to leverage binary caches. If not, define
# custom 'pkgs' for the platform.
# https://en.wikipedia.org/wiki/Raspberry_Pi#Specifications
let
  mkPlatformPkgs = platform: (
    import nixpkgs {
      # Just setting the 'system' seems to screw up 'buildPlatform'/'hostPlatform'
      inherit (platform) crossSystem;
      inherit localSystem overlays;
      config = nixpkgsConfig;
    }
  );

  # Evaluate the 'crossSystem' config using the 'elaborate' function,
  # This generates detailed attrsets which can be compared.
  # https://github.com/NixOS/nixpkgs/blob/master/lib/systems/default.nix#L63
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/default.nix#L82
  platforms = let
    mkPkgs = crossSystem: (
      import nixpkgs {
        # Just setting the 'system' seems to screw up 'buildPlatform'/'hostPlatform'
        inherit crossSystem localSystem overlays;
        config = nixpkgsConfig;
      }
    );
  in rec {
    raspberryPi = rec {
      board = "bcm2835";
      system = "armv6l-linux";
      crossSystem =
        lib.systems.elaborate (lib.mergeAttrs lib.systems.platforms.raspberrypi {config = "armv6l-unknown-linux-gnueabihf";});
      pkgs = mkPkgs crossSystem;
      #pkgsCross = pkgs.pkgsCross.raspberryPi;
    };
    raspberryPiZero = raspberryPi;
    raspberryPiZeroW = raspberryPi;
    raspberryPi2 = rec {
      board = "bcm2836";
      system = "armv7l-linux";
      crossSystem =
        lib.systems.elaborate (lib.mergeAttrs lib.systems.platforms.raspberrypi2 {config = "armv7l-unknown-linux-gnueabihf";});
      pkgs = mkPkgs crossSystem;
      #pkgsCross = pkgs.pkgsCross.armv7l-hf-multiplatform;
    };
    raspberryPi3 = rec {
      board = "bcm2837";
      system = "aarch64-linux";
      crossSystem = lib.systems.elaborate (lib.mergeAttrs lib.systems.platforms.aarch64-multiplatform {config = "aarch64-unknown-linux-gnu";});
      pkgs = mkPkgs crossSystem;
      #pkgsCross = pkgs.pkgsCross.aarch64-multiplatform;
    };
    raspberryPi4 = {
      board = "bcm2711";
      inherit (raspberryPi3) system crossSystem pkgs;
      #pkgsCross = pkgs.pkgsCross.aarch64-multiplatform;
    };
    raspberryPiZero2W = {
      board = "bcm2710";
      inherit (raspberryPi3) system crossSystem pkgs;
      #pkgsCross = pkgs.pkgsCross.aarch64-multiplatform;
    };

    systems = {
      "armv6l-linux" = {
        platforms = [
          raspberryPi
          raspberryPiZero
          raspberryPiZeroW
        ];
        pkgs = raspberryPi.pkgs;
      };
      "armv7l-linux" = {
        platforms = [
          raspberryPi2
        ];
        pkgs = raspberryPi2.pkgs;
      };
      "aarch64-linux" = {
        platforms = [
          raspberryPi3
          raspberryPi4
          raspberryPiZero2W
        ];
        pkgs = raspberryPi3.pkgs;
      };
    };
  };
in
  platforms
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

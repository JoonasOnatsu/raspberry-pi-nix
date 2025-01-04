{
  nixpkgs,
  lib ? nixpkgs.lib,
  localSystem ? "x86_64-linux",
  ...
}: let
  pkgs = import nixpkgs {
    system = localSystem;
    config = {
      allowUnsupportedSystem = true;
      allowUnfree = true;
    };
  };

  # Attributes for each Raspberry Pi system.
  # We need to use the platform definitions
  # to wrestle nixpkgs evaluation into
  # using binary cache.
  # https://en.wikipedia.org/wiki/Raspberry_Pi#Specifications
  rpiSystems = rec {
    raspberryPi = {
      system = "armv6l-linux";
      board = "bcm2835";
      platform =
        lib.systems.platforms.raspberrypi
        // {
          config = "armv6l-unknown-linux-gnueabihf";
        };
      pkgsCross = pkgs.pkgsCross.raspberryPi;
    };
    raspberryPiZero = raspberryPi;
    raspberryPiZeroW = raspberryPi;
    raspberryPiZero2W = {
      system = "aarch64-linux";
      board = "bcm2710";
      platform =
        lib.systems.platforms.aarch64-multiplatform
        // {
          config = "aarch64-unknown-linux-gnu";
        };
      pkgsCross = pkgs.pkgsCross.aarch64-multiplatform;
    };
    raspberryPi2 = {
      system = "armv7l-linux";
      board = "bcm2836";
      platform =
        lib.systems.platforms.raspberrypi2
        // {
          config = "armv7l-unknown-linux-gnueabihf";
        };
      pkgsCross = pkgs.pkgsCross.armv7l-hf-multiplatform;
    };
    raspberryPi3 = {
      system = "aarch64-linux";
      board = "bcm2837";
      platform =
        lib.systems.platforms.aarch64-multiplatform
        // {
          config = "aarch64-unknown-linux-gnu";
        };
      pkgsCross = pkgs.pkgsCross.aarch64-multiplatform;
    };
    raspberryPi4 = {
      system = "aarch64-linux";
      board = "bcm2711";
      platform =
        lib.systems.platforms.aarch64-multiplatform
        // {
          config = "aarch64-unknown-linux-gnu";
        };
      pkgsCross = pkgs.pkgsCross.aarch64-multiplatform;
    };
  };

  mkCrossPkgs = cfg: (
    import nixpkgs {
      # Just setting the 'system' seems to screw up 'buildPlatform'/'hostPlatform'
      inherit localSystem;
      crossSystem = cfg.platform;
      config = {
        allowUnsupportedSystem = true;
        allowUnfree = true;
      };
    }
  );
in (lib.mapAttrs (
    plat: cfg: {
      config = cfg;
      pkgsCross =
        if builtins.hasAttr "pkgsCross" cfg
        then cfg.pkgsCross
        else mkCrossPkgs cfg;
    }
  )
  rpiSystems)

{
  description = "raspberry-pi nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    #nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    u-boot-src = {
      flake = false;
      url = "https://ftp.denx.de/pub/u-boot/u-boot-2024.07.tar.bz2";
    };
    rpi-linux-6_6_54-src = {
      flake = false;
      url = "github:raspberrypi/linux/rpi-6.6.y";
    };
    rpi-linux-6_10_12-src = {
      flake = false;
      url = "github:raspberrypi/linux/rpi-6.10.y";
    };
  };

  nixConfig = {
    extra-substituters = [
      "http://cache.onatsu.net"
    ];
    extra-trusted-public-keys = [
      "cache.onatsu.net:QUbCckF117/Gv2kkXTm8mRsBwW7iWV/q+G5tmx9AWKA="
    ];
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    systems = [
      "armv6l-linux"
      "armv7l-linux"
      "aarch64-linux"
    ];
    lib = nixpkgs.lib;

    out = system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {};
        overlays = builtins.attrValues self.overlays;
      };
      appliedOverlay = self.overlays.default pkgs pkgs;
    in {
      packages = {
        inherit (appliedOverlay) libpisp libcamera rpicam-apps;
      };
    };
  in
    flake-utils.lib.eachSystem systems
    out
    // {
      overlays = {
        default = final: prev:
          import ./packages {
            pkgs = prev;
          };

        modifications = final: prev: {
          unbound = prev.unbound.overrideAttrs (
            finalAttrs: previousAttrs: {
              nativeBuildInputs = (previousAttrs.nativeBuildInputs or []) ++ [final.buildPackages.bison];
            }
          );

          # Pixman from stable 24.11 (v0.43.4) won't build
          # on armv6/armv7, but the version (v0.44.2) from
          # unstable builds, so make an override to change
          # the derivation to same as in unstable.
          pixman = prev.pixman.overrideAttrs (
            finalAttrs: previousAttrs: {
              version = "0.44.2";
              src = final.fetchurl {
                urls = with finalAttrs; [
                  "mirror://xorg/individual/lib/${pname}-${version}.tar.gz"
                  "https://cairographics.org/releases/${pname}-${version}.tar.gz"
                ];
                hash = "sha256-Y0kGHOGjOKtpUrkhlNGwN3RyJEII1H/yW++G/HGXNGY=";
              };
              mesonFlags = [];
            }
          );

          # Use the latest available firmware
          raspberrypifw = prev.raspberrypifw.overrideAttrs (
            finalAttrs: previousAttrs: {
              version = "1.20241126";
              src = final.fetchFromGitHub {
                owner = "raspberrypi";
                repo = "firmware";
                rev = finalAttrs.version;
                hash = "sha256-MCutxzdSFoZ4hn2Fxk2AHHgWCt/Jgc+reqJZHUuSKOc=";
              };
            }
          );
        };
      };
    };

  #packages = forAllSystems (
  #  system: let
  #    pkgs = nixpkgsFor.${system};
  #    pkgs' = pkgs.pkgsCross.raspberryPi;
  #  in {
  #    libpisp = pkgs'.callPackage ./packages/libpisp.nix {};
  #    rpicam-apps = pkgs'.callPackage ./packages/rpicam-apps.nix {};
  #    #example-sd-image = self.nixosConfigurations.${system}.rpi-example.config.system.build.sdImage;
  #    #firmware = pkgs.raspberrypifw;
  #    #libcamera = pkgs.libcamera;
  #    #wireless-firmware = pkgs.raspberrypiWirelessFirmware;
  #    #uboot-rpi-arm64 = pkgs.uboot-rpi-arm64;
  #  }
  #);

  #packages = forAllSystems (
  #  system: let
  #    pkgs = nixpkgsFor.${system};
  #  in
  #    with pkgs.lib; let
  #      kernels = foldlAttrs (acc: kernel-version: board-attr-set:
  #        foldlAttrs
  #        (acc: board-version: drv:
  #          acc
  #          // {
  #            "linux-${kernel-version}-${board-version}" = drv;
  #          })
  #        acc
  #        board-attr-set) {}
  #      pkgs.rpi-kernels;
  #    in {
  #      inherit kernels;
  #      example-sd-image = self.nixosConfigurations.${system}.rpi-example.config.system.build.sdImage;
  #      firmware = pkgs.raspberrypifw;
  #      libcamera = pkgs.libcamera;
  #      wireless-firmware = pkgs.raspberrypiWirelessFirmware;
  #      uboot-rpi-arm64 = pkgs.uboot-rpi-arm64;
  #    }
  #);

  #overlays = {
  #  core = import ./overlays/core.nix (builtins.removeAttrs inputs ["self"]);
  #  libcamera = import ./overlays/libcamera.nix (builtins.removeAttrs inputs ["self"]);
  #};
  #nixosModules = forAllSystems (system: {
  #  raspberry-pi = let
  #    pinned = nixpkgsFor.${system};
  #  in
  #    import ./rpi {
  #      inherit pinned;
  #      core-overlay = self.overlays.core;
  #      libcamera-overlay = self.overlays.libcamera;
  #    };
  #  sd-image = import ./sd-image;
  #});
  #nixosConfigurations = forAllSystems (
  #  system: {
  #    rpi-example = nixpkgs.lib.nixosSystem {
  #      inherit system;
  #      modules = [
  #        self.nixosModules.${system}.raspberry-pi
  #        self.nixosModules.${system}.sd-image
  #        ./example
  #      ];
  #    };
  #  }
  #);
}

{
  description = "raspberry-pi nixos configuration";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    #flake-utils.url = "github:numtide/flake-utils";
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
    rpi-firmware-src = {
      flake = false;
      url = "github:raspberrypi/firmware/1.20241001";
    };
    rpi-firmware-nonfree-src = {
      flake = false;
      url = "github:RPi-Distro/firmware-nonfree/bookworm";
    };
    rpi-bluez-firmware-src = {
      flake = false;
      url = "github:RPi-Distro/bluez-firmware/bookworm";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    #inherit (self) outputs;
    localSystem = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${localSystem};
    lib = nixpkgs.lib;

    platforms = import ./lib/platforms.nix {inherit nixpkgs;};

    # Do this complicated evaluation stuff here
    # to make Nix understand that we want to use
    # the binary cache to avoid building everything
    # from scratch.
    #forEachSystem = systems: fn: lib.genAttrs systems (system: fn system);
    #forAllSystems = forEachSystem rpiSystems;
    forEachPlatform = fn: lib.mapAttrs (plat: cfg: fn cfg.pkgsCross cfg) platforms;
  in {
    inherit lib;
    packages = forEachPlatform (
      pkgs: cfg:
        import ./packages {inherit pkgs;}
    );

    #formatter = forEachPlatform (_: pkgsNative.alejandra);
    #checks = forEachPlatform (pkgs': self.packages.${pkgs'.system});
  };

  # Format the Nix code in this flake
  # Alejandra is a Nix formatter with a beautiful output
  #formatter = forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.alejandra);
  #checks = forAllSystems (system: self.packages.${system});

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

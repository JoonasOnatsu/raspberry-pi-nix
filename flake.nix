{
  description = "raspberry-pi nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
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
    rpi-firmware-src = {
      flake = false;
      url = "github:raspberrypi/firmware/1.20241001";
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
    ...
  }: let
    inherit (self) outputs;

    lib = nixpkgs.lib;
    localSystem = {
      config = "x86_64-unknown-linux-gnu";
      system = "x86_64-linux";
    };

    platforms = import ./lib/platforms.nix {
      inherit nixpkgs localSystem;
      overlays =
        if builtins.hasAttr "overlays" outputs
        then builtins.attrValues outputs.overlays
        else [];
    };

    # Do this complicated evaluation stuff here
    # to make Nix understand that we want to use
    # the binary cache to avoid building everything
    # from scratch.
    forEachSystem = fn:
      lib.genAttrs (builtins.attrNames platforms.systems) (
        system: let
          pkgs = platforms.systems.${system}.pkgs;
        in
          fn system pkgs
      );
  in
    {
      #inherit lib platforms;
      packages = forEachSystem (_: pkgs: import ./packages {inherit pkgs;});
      overlays = import ./overlays {inherit inputs outputs;};

      checks = forEachSystem (system: _: outputs.packages.${system});

      # Format the Nix code in this flake
      # Alejandra is a Nix formatter with a beautiful output
      #formatter = forEachSystem (_: pkgs: pkgs.alejandra);
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    }
    // (lib.concatMapAttrs (platform: attrs: let
      packagesForThisPlatform =
        if builtins.isAttrs outputs.packages.${attrs.system}
        then {packages = outputs.packages.${attrs.system};}
        else {};
    in {
      "${platform}" = packagesForThisPlatform;
    }) (builtins.removeAttrs platforms ["systems"]));

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

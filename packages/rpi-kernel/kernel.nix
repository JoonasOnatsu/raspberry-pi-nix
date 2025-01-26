{
  stdenv,
  lib,
  buildPackages,
  fetchFromGitHub,
  fetchpatch,
  perl,
  buildLinux,
  boardName,
  defConfig,
  ...
} @ args: let
  # NOTE: raspberrypifw & raspberryPiWirelessFirmware should be updated with this
  modDirVersion = "6.6.51";
  tag = "stable_20241008";
in
  lib.overrideDerivation
  (buildLinux (
    args
    // {
      version = "${modDirVersion}-${tag}";
      inherit modDirVersion;
      pname = "${boardName}-linux-rpi";

      src = fetchFromGitHub {
        owner = "raspberrypi";
        repo = "linux";
        rev = tag;
        hash = "sha256-UWUTeCpEN7dlFSQjog6S3HyEWCCnaqiUqV5KxCjYink=";
      };

      defconfig = defConfig;

      structuredExtraConfig =
        (args.structuredExtraConfig or {})
        // (with lib.kernel; {
          # The perl script to generate kernel options sets unspecified
          # parameters to `m` if possible [1]. This results in the
          # unspecified config option KUNIT [2] getting set to `m` which
          # causes DRM_VC4_KUNIT_TEST [3] to get set to `y`.
          #
          # This vc4 unit test fails on boot due to a null pointer
          # exception with the existing config. I'm not sure why, but in
          # any case, the DRM_VC4_KUNIT_TEST config option itself states
          # that it is only useful for kernel developers working on the
          # vc4 driver. So, I feel no need to deviate from the standard
          # rpi kernel and attempt to successfully enable this test and
          # other unit tests because the nixos perl script has this
          # sloppy "default to m" behavior. So, I set KUNIT to `n`.
          #
          # [1] https://github.com/NixOS/nixpkgs/blob/85bcb95aa83be667e562e781e9d186c57a07d757/pkgs/os-specific/linux/kernel/generate-config.pl#L1-L10
          # [2] https://github.com/raspberrypi/linux/blob/1.20230405/lib/kunit/Kconfig#L5-L14
          # [3] https://github.com/raspberrypi/linux/blob/bb63dc31e48948bc2649357758c7a152210109c4/drivers/gpu/drm/vc4/Kconfig#L38-L52
          KUNIT = no;
        });

      features =
        {
          efiBootStub = false;
        }
        // (args.features or {});

      kernelPatches = args.kernelPatches or [];

      extraMeta = {
        platforms = with lib.platforms; arm ++ aarch64;
        hydraPlatforms = ["aarch64-linux"];
      };
    }
    // (args.argsOverride or {})
  ))
  (oldAttrs: {
    postConfigure = ''
      # The v7 defconfig has this set to '-v7' which screws up our modDirVersion.
      sed -i $buildRoot/.config -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
      sed -i $buildRoot/include/config/auto.conf -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
    '';

    # Make copies of the DTBs named after the upstream names so that U-Boot finds them.
    # This is ugly as heck, but I don't know a better solution so far.
    postFixup =
      ''
        dtbDir=${
          if stdenv.hostPlatform.isAarch64
          then "$out/dtbs/broadcom"
          else "$out/dtbs"
        }
        rm $dtbDir/bcm283*.dtb
        copyDTB() {
          cp -v "$dtbDir/$1" "$dtbDir/$2"
        }
      ''
      + lib.optionalString (lib.elem stdenv.hostPlatform.system ["armv6l-linux"]) ''
        copyDTB bcm2708-rpi-zero-w.dtb bcm2835-rpi-zero.dtb
        copyDTB bcm2708-rpi-zero-w.dtb bcm2835-rpi-zero-w.dtb
        copyDTB bcm2708-rpi-b.dtb bcm2835-rpi-a.dtb
        copyDTB bcm2708-rpi-b.dtb bcm2835-rpi-b.dtb
        copyDTB bcm2708-rpi-b.dtb bcm2835-rpi-b-rev2.dtb
        copyDTB bcm2708-rpi-b-plus.dtb bcm2835-rpi-a-plus.dtb
        copyDTB bcm2708-rpi-b-plus.dtb bcm2835-rpi-b-plus.dtb
        copyDTB bcm2708-rpi-b-plus.dtb bcm2835-rpi-zero.dtb
        copyDTB bcm2708-rpi-cm.dtb bcm2835-rpi-cm.dtb
      ''
      + lib.optionalString (lib.elem stdenv.hostPlatform.system ["armv7l-linux"]) ''
        copyDTB bcm2709-rpi-2-b.dtb bcm2836-rpi-2-b.dtb
      ''
      + lib.optionalString
      (lib.elem stdenv.hostPlatform.system [
        "armv7l-linux"
        "aarch64-linux"
      ])
      ''
        copyDTB bcm2710-rpi-zero-2.dtb bcm2837-rpi-zero-2.dtb
        copyDTB bcm2710-rpi-zero-2-w.dtb bcm2837-rpi-zero-2-w.dtb
        copyDTB bcm2710-rpi-3-b.dtb bcm2837-rpi-3-b.dtb
        copyDTB bcm2710-rpi-3-b-plus.dtb bcm2837-rpi-3-a-plus.dtb
        copyDTB bcm2710-rpi-3-b-plus.dtb bcm2837-rpi-3-b-plus.dtb
        copyDTB bcm2710-rpi-cm3.dtb bcm2837-rpi-cm3.dtb
        copyDTB bcm2711-rpi-4-b.dtb bcm2838-rpi-4-b.dtb
      '';
  })

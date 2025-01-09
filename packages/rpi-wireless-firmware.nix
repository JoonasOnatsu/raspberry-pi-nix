{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}: let
  bluez-firmware = fetchFromGitHub {
    owner = "RPi-Distro";
    repo = "bluez-firmware";
    rev = "78d6a07730e2d20c035899521ab67726dc028e1c";
    hash = "sha256-4gnK0KbqFnjBmWia9Jt2gveVWftmHrprpwBqYVqE/k0=";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "raspberrypi-wireless-firmware";
    version = "2024-02-26";

    src = fetchFromGitHub {
      owner = "RPi-Distro";
      repo = "firmware-nonfree";
      rev = "a6ed59a078d52ad72f0f2b99e68f324e7411afa1";
      hash = "sha256-4gnK0KbqFnjBmWia9Jt2gveVWftmHrprpwBqYVqE/k0=";
    };

    #srcs = [];

    sourceRoot = ".";

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    # Firmware blobs do not need fixing and should not be modified
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/firmware/brcm"
      mkdir -p "$out/lib/firmware/cypress"

      # Wifi firmware
      cp -rv ./debian/config/brcm80211/ $out/lib/firmware/

      # Bluetooth firmware
      #cp -rv "${bluez-firmware}/debian/firmware/broadcom/." "$out/lib/firmware/brcm"

      runHook postInstall
    '';

    meta = with lib; {
      description = "Firmware for builtin Wifi/Bluetooth devices in the Raspberry Pi 3+ and Zero W";
      homepage = "https://github.com/RPi-Distro/firmware-nonfree";
      license = licenses.unfreeRedistributableFirmware;
      platforms = platforms.linux;
      maintainers = with maintainers; [lopsided98];
    };
  }

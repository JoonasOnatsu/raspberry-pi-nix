{pkgs, ...}: rec {
  #dtmerger = pkgs.callPackage ./dtmerger.nix {};
  libpisp = pkgs.callPackage ./libpisp {};
  libcamera = pkgs.callPackage ./libcamera {inherit libpisp;};
  rpicam-apps = pkgs.callPackage ./rpicam-apps {inherit libpisp libcamera;};
  raspberrypi-wireless-firmware = pkgs.callPackage ./raspberrypi-wireless-firmware {};
}

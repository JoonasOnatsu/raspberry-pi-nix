{pkgs, ...}: rec {
  #inherit pkgs;

  libpisp = pkgs.callPackage ./libpisp.nix {};
  libcamera = pkgs.callPackage ./libcamera {inherit libpisp;};
  #dtmerger = pkgs.callPackage ./dtmerger.nix {};
  rpicam-apps = pkgs.callPackage ./rpicam-apps.nix {inherit libpisp libcamera;};
  #rpi-wireless-firmware = pkgs.callPackage ./rpi-wireless-firmware.nix {};
}

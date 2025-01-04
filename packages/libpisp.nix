# https://github.com/nix-community/raspberry-pi-nix
# https://github.com/sergei-mironov/nixos-raspi-camera/blob/main/nix/libpisp.nix
{
  stdenv,
  lib,
  fetchgit,
  boost,
  cmake,
  meson,
  ninja,
  nlohmann_json,
  pkg-config,
}:
stdenv.mkDerivation rec {
  pname = "libpisp";
  version = "1.0.7";
  src = fetchgit {
    url = "https://github.com/raspberrypi/libpisp";
    rev = "v${version}";
    hash = "sha256-Fo2UJmQHS855YSSKKmGrsQnJzXog1cdpkIOO72yYAM4=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    #cmake
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    boost
    nlohmann_json
  ];

  mesonFlags = [
    "-Dlogging=disabled"
  ];

  env = {
    # Meson is no longer able to pick up Boost automatically.
    # https://github.com/NixOS/nixpkgs/issues/86131
    #BOOST_INCLUDEDIR = "${lib.getDev boost}/include";
    #BOOST_LIBRARYDIR = "${lib.getLib boost}/lib";

    # Fixes error on a deprecated declaration
    NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-declarations";
  };

  meta = {
    description = "A helper library to generate run-time configuration for the Raspberry Pi ISP (PiSP), consisting of the Frontend and Backend hardware components.";
    homepage = "https://github.com/raspberrypi/libpisp";
    license = lib.licenses.bsd2;
    platforms = [
      "aarch64-linux"
      "armv6l-linux"
      "armv7l-linux"
    ];
  };
}

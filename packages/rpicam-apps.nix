{
  stdenv,
  lib,
  fetchgit,
  boost,
  cmake,
  ffmpeg,
  libcamera,
  libdrm,
  libepoxy,
  libexif,
  libjpeg,
  libpisp,
  libpng,
  libtiff,
  meson,
  ninja,
  opencv,
  pkg-config,
  python3,
  python3Packages,
}:
stdenv.mkDerivation rec {
  pname = "rpicam-apps";
  version = "v1.5.2";

  src = fetchgit {
    url = "https://github.com/raspberrypi/rpicam-apps";
    rev = "${version}";
    #hash = "sha256-dDb4/SL5SPuBhmp1g8h8ZMq9PnG2SZMIik2gnO8PkuY=";
    hash = "sha256-qCYGrcibOeGztxf+sd44lD6VAOGoUNwRqZDdAmcTa/U=";
  };

  strictDeps = true;

  outputs = ["out" "dev"];

  postPatch = ''
    patchShebangs utils/
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3
    cmake
    boost.dev
  ];

  buildInputs = [
    boost
    ffmpeg
    ffmpeg.dev
    libcamera
    libdrm
    libepoxy
    libexif
    libjpeg
    libpisp
    libpng
    libtiff
    ninja
    opencv
  ];

  mesonFlags = [
    "-Denable_libav=enabled"
    "-Denable_drm=enabled"
    "-Denable_opencv=enabled"
    "-Ddownload_hailo_models=false"
    "-Denable_egl=disabled"
    "-Denable_hailo=disabled"
    "-Denable_qt=disabled"
    "-Denable_tflite=disabled"
  ];
  env = {
    # Fixes error on a deprecated declaration
    NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-declarations";
    #NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-declarations -I${lib.getDev boost}/include -L${lib.getDev boost}/lib";

    # Meson is no longer able to pick up Boost automatically.
    # https://github.com/NixOS/nixpkgs/issues/86131
    BOOST_INCLUDEDIR = "${lib.getDev boost}/include";
    BOOST_LIBRARYDIR = "${lib.getLib boost}/lib";
  };

  meta = {
    description = "This is a small suite of libcamera-based applications to drive the cameras on a Raspberry Pi platform.";
    homepage = "https://github.com/raspberrypi/rpicam-apps";
    license = lib.licenses.bsd2;
    platforms = [
      "aarch64-linux"
      "armv6l-linux"
      "armv7l-linux"
    ];
  };
}

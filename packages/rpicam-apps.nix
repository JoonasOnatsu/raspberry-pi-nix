{
  stdenv,
  lib,
  fetchgit,
  meson,
  ninja,
  cmake,
  pkg-config,
  boost,
  ffmpeg,
  libcamera,
  libpisp,
  libdrm,
  libjpeg,
  libepoxy,
  libexif,
  libpng,
  libtiff,
  opencv,
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
    cmake
    pkg-config
    boost.dev
    python3
  ];

  buildInputs = [
    libcamera
    libpisp
    ffmpeg
    ffmpeg.dev
    libdrm
    libjpeg
    libepoxy
    libexif
    libpng
    libtiff
    opencv
  ];

  mesonFlags = [
    "-Ddownload_hailo_models=false"
    (lib.mesonEnable "enable_libav" false)
    (lib.mesonEnable "enable_drm" true)
    (lib.mesonEnable "enable_opencv" true)
    (lib.mesonEnable "enable_egl" false)
    (lib.mesonEnable "enable_hailo" false)
    (lib.mesonEnable "enable_qt" false)
    (lib.mesonEnable "enable_tflite" false)
  ];
  env = {
    # Fixes error on a deprecated declaration
    NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-declarations";
    #NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-declarations -I${lib.getDev boost}/include -L${lib.getDev boost}/lib";

    # Meson is no longer able to pick up Boost automatically.
    # https://github.com/NixOS/nixpkgs/issues/86131
    #BOOST_INCLUDEDIR = "${lib.getDev boost}/include";
    #BOOST_LIBRARYDIR = "${lib.getLib boost}/lib";
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

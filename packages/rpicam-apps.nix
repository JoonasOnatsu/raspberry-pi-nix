# https://github.com/raspberrypi/rpicam-apps/tree/main
{
  stdenv,
  lib,
  fetchgit,
  meson,
  ninja,
  cmake,
  pkg-config,
  git,
  boost,
  libcamera,
  libpisp,
  libdrm,
  libjpeg,
  libepoxy,
  libexif,
  libpng,
  libtiff,
  python3,
  python3Packages,
  withLibav ? true,
  ffmpeg, # withLibav
  withOpenCV ? lib.meta.availableOn stdenv.hostPlatform opencv,
  opencv, # withOpenCV
  withQt ? false,
  qt5, # withQt
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

  nativeBuildInputs =
    [
      meson
      ninja
      cmake
      pkg-config
      python3
      git
    ]
    ++ (lib.optional withQt qt5.wrapQtAppsHook);

  buildInputs =
    [
      boost
      libcamera
      libpisp
      libdrm
      libjpeg
      libexif
      libpng
      libtiff
      #libepoxy
    ]
    ++ (lib.optionals withLibav [
      ffmpeg
      ffmpeg.dev
    ])
    ++ (lib.optional withOpenCV opencv)
    ++ (lib.optionals withQt [
      qt5.qtbase
      qt5.qttools
    ]);

  mesonFlags = [
    "-Ddownload_hailo_models=false"
    "-Ddownload_imx500_models=false"
    "-Denable_drm=enabled"
    (lib.mesonEnable "enable_libav" withLibav)
    (lib.mesonEnable "enable_opencv" withOpenCV)
    (lib.mesonEnable "enable_qt" withQt)
    "-Denable_egl=disabled"
    "-Denable_hailo=disabled"
    "-Denable_tflite=disabled"
  ];

  # Fixes error on a deprecated declaration
  env.NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-declarations";

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

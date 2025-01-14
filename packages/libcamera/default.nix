# https://github.com/RPi-Distro/libcamera/blob/pios/bookworm/debian/control
{
  stdenv,
  lib,
  fetchFromGitHub,
  breakpointHook,
  boost,
  gnutls,
  gst_all_1,
  libevent,
  libpisp,
  libyaml,
  lttng-ust,
  makeFontsConf,
  meson,
  ninja,
  openssl,
  pkg-config,
  python3,
  python3Packages,
  systemd,
  withSDL ? true,
  SDL2,
  libdrm,
  libjpeg,
  withQcam ? false,
  libtiff,
  qt5,
}:
stdenv.mkDerivation {
  pname = "libcamera";
  version = "v0.3.2+rpt20240927";
  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "libcamera";
    rev = "7330f29b38b7fa32f753297b4d1c8ecbbfcf0df5";
    hash = "sha256-Fo2UJmQHS855YSSKKmGrsQnJzXog1cdpkIOO72yYAM4=";
  };

  patches = [
    ./patches/0001_libcamera_installed.patch
    ./patches/0002_libcamera_fix_python_paths.patch
    ./patches/0003_ipc_no_timeout.patch
  ];

  strictDeps = true;

  outputs = [
    "out"
    "dev"
  ];

  # libcamera signs the IPA module libraries at install time, but they are then
  # modified by stripping and RPATH fixup. Therefore, we need to generate the
  # signatures again ourselves. For reproducibility, we use a static private key.
  #
  # If this is not done, libcamera will still try to load them, but it will
  # isolate them in separate processes, which can cause crashes for IPA modules
  # that are not designed for this (notably ipa_rpi.so).
  # https://github.com/RPi-Distro/libcamera/blob/pios/bookworm/utils/gen-ipa-priv-key.sh
  # https://github.com/RPi-Distro/libcamera/blob/pios/bookworm/src/ipa/ipa-sign-install.sh
  preBuild = ''
    ninja src/ipa-priv-key.pem
    install -D ${./ipa-priv-key.pem} src/ipa-priv-key.pem
  '';

  postPatch = ''
    patchShebangs utils/
    patchShebangs src/py/
  '';

  # https://github.com/NixOS/nixpkgs/issues/305858
  nativeBuildInputs =
    [
      #breakpointHook
      meson
      ninja
      openssl
      pkg-config
      python3
    ]
    ++ (with python3Packages; [
      jinja2
      ply
      pybind11
      pyyaml
    ])
    ++ (lib.optional withQcam qt5.wrapQtAppsHook);

  buildInputs =
    [
      # General deps
      boost
      libpisp

      # IPA and signing
      openssl
      gnutls

      # Gstreamer integration
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base

      # Cam integration
      libevent

      # Hotplugging (udev)
      systemd

      # lttng tracing
      lttng-ust

      # yamlparser
      libyaml
    ]
    ++ (lib.optionals stdenv.hostPlatform.isAarch32 (with python3Packages; [
      # Build uses the host library by default, which causes
      # an error when building on a 64-bit host to 32-bit target,
      # e.g. x86_64-linux -> armv6l. Adding this to build deps
      # fixes this issue.
      pybind11
    ]))
    ++ (lib.optionals withSDL [
      SDL2
      libdrm # Cam integration
      libjpeg
    ])
    ++ (lib.optionals withQcam [
      libtiff
      qt5.qtbase
      qt5.qttools
    ]);

  mesonFlags = [
    "--buildtype=release"
    "-Dpipelines=rpi/vc4,rpi/pisp"
    "-Dipas=rpi/vc4,rpi/pisp"
    "-Dgstreamer=enabled"
    "-Dpycamera=enabled"
    "-Dudev=enabled"
    "-Dv4l2=true"
    "-Dtest=false"
    "-Dqcam=${
      if withQcam
      then "enabled"
      else "disabled"
    }"
    # Documentation breaks binary compatibility.
    # Given that upstream also provides public documentation,
    # we can disable it here.
    "-Ddocumentation=disabled"
    # Tries to unconditionally download gtest when enabled
    "-Dlc-compliance=disabled"
    # Avoid blanket -Werror to evade build failures on less
    # tested compilers.
    "-Dwerror=false"
  ];

  # Fixes error on a deprecated declaration
  env.NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-declarations";

  # Silence fontconfig warnings about missing config
  FONTCONFIG_FILE = makeFontsConf {fontDirectories = [];};

  meta = with lib; {
    description = "An open source camera stack and framework for Linux, Android, and ChromeOS";
    homepage = "https://libcamera.org";
  };
}

{
  stdenv,
  lib,
  fetchgit,
  breakpointHook,
  doxygen,
  graphviz,
  gst_all_1,
  gtest,
  libdrm,
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
  systemd, # for libudev
  withQcam ? false,
  qt5, # withQcam
  libtiff, # withQcam
}:
stdenv.mkDerivation {
  pname = "libcamera";
  version = "v0.3.1"; # v0.3.1+rpt20240906

  src = fetchgit {
    url = "https://github.com/raspberrypi/libcamera";
    rev = "69a894c4adad524d3063dd027f5c4774485cf9db";
    hash = "sha256-KH30jmHfxXq4j2CL7kv18DYECJRp9ECuWNPnqPZajPA=";
  };

  patches = [
    ./libcamera-installed.patch
    ./libcamera-no-timeout.patch
  ];

  strictDeps = true;

  outputs = ["out" "dev"];

  # libcamera signs the IPA module libraries at install time, but they are then
  # modified by stripping and RPATH fixup. Therefore, we need to generate the
  # signatures again ourselves. For reproducibility, we use a static private key.
  #
  # If this is not done, libcamera will still try to load them, but it will
  # isolate them in separate processes, which can cause crashes for IPA modules
  # that are not designed for this (notably ipa_rpi.so).
  preBuild = ''
    ninja src/ipa-priv-key.pem
    install -D ${./libcamera-ipa-priv-key.pem} src/ipa-priv-key.pem
  '';

  postPatch = ''
    patchShebangs utils/
    patchShebangs src/py/
  '';

  nativeBuildInputs =
    [
      breakpointHook
      doxygen
      graphviz
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
      sphinx
    ])
    ++ (lib.optional withQcam qt5.wrapQtAppsHook);

  buildInputs =
    [
      # IPA and signing
      openssl

      # gstreamer integration
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base

      # cam integration
      libevent
      libdrm

      # hotplugging
      systemd

      # lttng tracing
      lttng-ust

      # yamlparser
      libyaml

      gtest
      libpisp
    ]
    ++ (lib.optionals withQcam [
      libtiff
      qt5.qtbase
      qt5.qttools
    ]);

  mesonFlags = [
    "--buildtype=release"
    "-Dpipelines=rpi/vc4,rpi/pisp"
    "-Dipas=rpi/vc4,rpi/pisp"
    "-Dv4l2=true"
    "-Dgstreamer=enabled"
    "-Dpycamera=enabled"
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
    #"-Dwerror=false"
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

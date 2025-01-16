# This file defines overlays
{
  inputs,
  outputs,
  ...
}: {
  # Add custom packages from the 'packages' directory
  #additions = final: _prev: import ../packages {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    unbound = prev.unbound.overrideAttrs (
      finalAttrs: previousAttrs: {
        nativeBuildInputs = (previousAttrs.nativeBuildInputs or []) ++ [final.buildPackages.bison];
      }
    );

    # Pixman from stable 24.11 (v0.43.4) won't build
    # on armv6/armv7, but the version (v0.44.2) from
    # unstable builds, so make an override to change
    # the derivation to same as in unstable.
    pixman = prev.pixman.overrideAttrs (
      finalAttrs: previousAttrs: {
        version = "0.44.2";
        src = final.fetchurl {
          urls = with finalAttrs; [
            "mirror://xorg/individual/lib/${pname}-${version}.tar.gz"
            "https://cairographics.org/releases/${pname}-${version}.tar.gz"
          ];
          hash = "sha256-Y0kGHOGjOKtpUrkhlNGwN3RyJEII1H/yW++G/HGXNGY=";
        };
        mesonFlags = [];
      }
    );
  };
}

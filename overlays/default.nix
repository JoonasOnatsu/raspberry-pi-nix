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
      oldAttrs: {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [final.buildPackages.bison];
      }
    );
  };
}

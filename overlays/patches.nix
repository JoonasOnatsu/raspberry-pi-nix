final: prev: {
  unbound = prev.unbound.overrideAttrs (
    oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [final.pkgs.bison];
    }
  );
}

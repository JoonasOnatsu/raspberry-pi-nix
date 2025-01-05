final: prev: {
  unbound = prev.unbound.overrideAttrs (
    oldAttrs: {
      buildInputs = (oldAttrs.buildInputs or []) ++ [final.pkgs.bison];
    }
  );
}

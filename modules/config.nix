{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hardware.raspberry-pi;

  renderConfig = let
    renderDTParam = x: "dtparam=" + x;

    renderOptions = opts: lib.strings.concatStringsSep "\n" (renderDTKeyValues opts);

    renderDTKeyValue = k: v:
      if builtins.isNull v.value
      then k
      else let
        vstr = builtins.toString v.value;
      in "${k}=${vstr}";

    renderDTKeyValues = kvs:
      lib.attrsets.mapAttrsToList renderDTKeyValue
      (lib.filterAttrs (_: v: v.enable) kvs);

    renderDTOverlay = {
      overlay,
      args,
    }:
      "dtoverlay="
      + overlay
      + "\n"
      + lib.strings.concatMapStringsSep "\n" renderDTParam args
      + "\n"
      + "dtoverlay=";

    renderBaseDTParams = params:
      lib.strings.concatMapStringsSep "\n" renderDTParam
      (renderDTKeyValues params);

    renderDTOverlays = overlays:
      lib.strings.concatMapStringsSep "\n" renderDTOverlay
      (lib.attrsets.mapAttrsToList
        (k: v: {
          overlay = k;
          args = renderDTKeyValues v.params;
        })
        (lib.filterAttrs (k: v: v.enable) overlays));

    renderConfigSection = key: {
      options,
      base-dt-params,
      dt-overlays,
    }: let
      collected = lib.concatStringsSep "\n" (lib.filter (x: x != "") [
        (renderOptions options)
        (renderBaseDTParams base-dt-params)
        (renderDTOverlays dt-overlays)
      ]);
    in ''
      [${key}]
      ${collected}
    '';
  in
    conf:
      lib.strings.concatStringsSep "\n"
      (lib.attrsets.mapAttrsToList renderConfigSection conf);

  configParamOpts = lib.types.submodule {
    options = {
      enable = lib.mkEnableOption "attr";
      value = with lib.types;
        lib.mkOption {
          type = nullOr (oneOf [int str bool]);
          default = null;
        };
    };
  };

  dtParamOpts = lib.types.submodule {
    options = {
      enable = lib.mkEnableOption "attr";
      value = with lib.types;
        lib.mkOption {
          type = nullOr (oneOf [int str bool]);
          default = null;
        };
    };
  };

  dtOverlayParamOpts = lib.types.submodule {
    options = {
      enable = lib.mkEnableOption "attr";
      value = with lib.types;
        lib.mkOption {
          type = attrsOf (submodule dtParamOpts);
          default = null;
        };
    };
  };

  configOpts = {
    options = {
      options = lib.mkOption {
        type = with lib.types; attrsOf (submodule configParamOpts);
        default = {};
        example = {
          enable_gic = {
            enable = true;
            value = true;
          };
          arm_boost = {
            enable = true;
            value = true;
          };
        };
      };
      dtparams = lib.mkOption {
        type = with lib.types; attrsOf (submodule dtParamOpts);
        default = {};
        example = {
          i2c = {
            enable = true;
            value = "on";
          };
          audio = {
            enable = true;
            value = "on";
          };
        };
        description = "Parameters to the base device tree";
      };
      dtoverlays = lib.mkOption {
        type = with lib.types; attrsOf (submodule dtOverlayParamOpts);
        default = {};
        example = {
          vc4-kms-v3d = {
            cma-256 = {
              enable = true;
            };
          };
        };
        description = "Device tree overlays to apply";
      };
    };
  };
in {
  options = {
    hardware.raspberry-pi = {
      config = lib.mkOption {
        type = with lib.types; attrsOf (submodule configOpts);
      };

      configGenerated = lib.mkOption {
        type = lib.types.str;
        description = "Generated config.txt contents";
        readOnly = true;
      };

      configOut = lib.mkOption {
        type = lib.types.package;
        default = pkgs.writeTextFile {
          name = "config.txt";
          text = ''
            # This is a generated file. Do not edit!
            ${cfg.configGenerated}
          '';
        };
      };
    };
  };
  config = {
    hardware.raspberry-pi.configGenerated = renderConfig cfg.config;
  };
}

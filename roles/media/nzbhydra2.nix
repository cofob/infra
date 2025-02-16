{ lib, config, ... }:

let cfg = config.roles.media.nzbhydra2;
in {
  options.roles.media.nzbhydra2 = {
    enable = lib.mkEnableOption "Enable nzbhydra2 role";
  };

  config = lib.mkIf cfg.enable { services.nzbhydra2.enable = true; };
}

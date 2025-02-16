{ lib, config, ... }:

let cfg = config.roles.media.nzbget;
in {
  options.roles.media.nzbget = {
    enable = lib.mkEnableOption "Enable nzbget role";
  };

  config = lib.mkIf cfg.enable { services.nzbget.enable = true; };
}

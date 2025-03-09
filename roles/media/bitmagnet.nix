{ lib, config, ... }:

let cfg = config.roles.media.bitmagnet;
in {
  options.roles.media.bitmagnet = {
    enable = lib.mkEnableOption "Enable bitmagnet role";
  };

  config = lib.mkIf cfg.enable {
    services.bitmagnet = {
      enable = true;
      openFirewall = true;
    };
  };
}

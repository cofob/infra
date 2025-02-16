{ lib, config, ... }:

let cfg = config.roles.media.jackett;
in {
  options.roles.media.jackett = {
    enable = lib.mkEnableOption "Enable jackett role";
  };

  config = lib.mkIf cfg.enable { services.jackett.enable = true; };
}

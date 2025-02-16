{ lib, config, ... }:

let cfg = config.roles.media.radarr;
in {
  options.roles.media.radarr = {
    enable = lib.mkEnableOption "Enable jellyfin role";
  };

  config = lib.mkIf cfg.enable { services.jellyfin = { enable = true; }; };
}

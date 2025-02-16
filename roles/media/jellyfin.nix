{ lib, config, ... }:

let cfg = config.roles.media.jellyfin;
in {
  options.roles.media.jellyfin = {
    enable = lib.mkEnableOption "Enable jellyfin role";
  };

  config = lib.mkIf cfg.enable { services.jellyfin = { enable = true; }; };
}

{ lib, config, ... }:

let cfg = config.roles.media.radarr;
in {
  options.roles.media.radarr = {
    enable = lib.mkEnableOption
      "Enable radarr, a Usenet/BitTorrent movie downloader role";
  };

  config = lib.mkIf cfg.enable {
    services.radarr = { enable = true; };
    users.users.radarr.extraGroups = [ "aria2" "nzbget" "deluge" ];
  };
}

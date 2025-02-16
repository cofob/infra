{ lib, config, ... }:

let cfg = config.roles.media.lidarr;
in {
  options.roles.media.lidarr = {
    enable = lib.mkEnableOption "Enable Lidarr, a Usenet/BitTorrent music downloader role";
  };

  config = lib.mkIf cfg.enable {
    services.lidarr = {
      enable = true;
      dataDir = "/mnt/music";
    };
  };
}

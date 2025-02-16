{ lib, config, pkgs, ... }:

let cfg = config.roles.media.navidrome;
in {
  options.roles.media.navidrome = {
    enable = lib.mkEnableOption "Enable navidrome music server role";
  };

  config = lib.mkIf cfg.enable {
    age.secrets.configs-navidrome.file =
      "${pkgs.secrets}/configs/navidrome.age";

    services.navidrome = {
      enable = true;
      settings = {
        MusicFolder = "/mnt/music";
        FFmpegPath = "${pkgs.ffmpeg}/bin/ffmpeg";
        TranscodingCacheSize = "4096MiB";
        BaseUrl = "https://music.madloba.org";
        EnableSharing = "true";
        LastFM.Enabled = "true";
      };
    };
    # Load the configuration with secrets
    systemd.services.navidrome.serviceConfig.EnvironmentFile =
      config.age.secrets.configs-navidrome.path;
  };
}

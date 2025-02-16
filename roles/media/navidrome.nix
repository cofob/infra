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
        TranscodingCacheSize = "40960MiB";
        BaseUrl = "https://music.madloba.org";
        EnableSharing = "true";
        EnableTranscodingConfig = "true";
        LastFM.Enabled = "true";
      };
    };
    # Load the configuration with secrets
    systemd.services.navidrome.serviceConfig.EnvironmentFile =
      config.age.secrets.configs-navidrome.path;

    security.acme.certs."music.madloba.org" = { };

    services.nginx = {
      enable = true;

      virtualHosts."music.madloba.org" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = { proxyPass = "http://127.0.0.1:4533"; };

        extraConfig = ''
          access_log /var/log/nginx/music.madloba.org-access.log json_combined;
          error_log /var/log/nginx/music.madloba.org-error.log;
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}

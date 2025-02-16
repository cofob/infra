{ config, pkgs, ... }:

{
  roles.utility.cf-ts-dnssync.enable = true;
  roles.utility.cf-opn-dnssync.enable = true;
  roles.media.navidrome.enable = true;
  roles.media.lidarr.enable = true;
  roles.media.nzbget.enable = true;
  roles.rss.miniflux.enable = true;

  age.secrets.credentials-cloudflare-tunnels-music = {
    file = "${pkgs.secrets}/credentials/cloudflare-tunnels/music.age";
    owner = "cloudflared";
    group = "cloudflared";
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      # music.madloba.org
      # lidarr.madloba.org
      # miniflux.madloba.org
      "74c5b52a-25a7-4a09-af63-5843be89e8cc" = {
        credentialsFile =
          "${config.age.secrets.credentials-cloudflare-tunnels-music.path}";
        default = "http_status:404";
      };
    };
  };

  networking.hostName = "services";
}

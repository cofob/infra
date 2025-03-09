{ config, pkgs, ... }:

{
  roles.utility.cf-ts-dnssync.enable = true;
  roles.utility.cf-opn-dnssync.enable = true;
  roles.utility.filebrowser.enable = true;
  roles.media.navidrome.enable = true;
  roles.media.jellyfin.enable = true;
  roles.media.lidarr.enable = true;
  roles.media.radarr.enable = true;
  roles.media.nzbget.enable = true;
  roles.media.nzbhydra2.enable = true;
  roles.media.jackett.enable = true;
  roles.media.deluge.enable = true;
  roles.media.bitmagnet.enable = true;
  roles.rss.miniflux.enable = true;

  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;
  virtualisation.podman.autoPrune.enable = true;

  age.secrets.credentials-cloudflare-tunnels-music = {
    file = "${pkgs.secrets}/credentials/cloudflare-tunnels/music.age";
    owner = "cloudflared";
    group = "cloudflared";
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "74c5b52a-25a7-4a09-af63-5843be89e8cc" = {
        credentialsFile =
          "${config.age.secrets.credentials-cloudflare-tunnels-music.path}";
        default = "http_status:404";
      };
    };
  };

  networking.hostName = "services";
}

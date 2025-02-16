{ config, pkgs, ... }:

{
  roles.utility.cf-ts-dnssync.enable = true;
  roles.utility.cf-opn-dnssync.enable = true;
  roles.media.navidrome.enable = true;

  age.secrets.credentials-cloudflare-tunnels-music.file =
    "${pkgs.secrets}/credentials/cloudflare-tunnels/music.age";

  services.cloudflared = {
    enable = true;
    tunnels = {
      # music.madloba.org
      "74c5b52a-25a7-4a09-af63-5843be89e8cc" = {
        credentialsFile =
          "${config.age.secrets.credentials-cloudflare-tunnels-music.path}";
        ingress = {
          "music.madloba.org" = { service = "http://localhost:4533"; };
        };
        default = "http_status:404";
      };
    };
  };

  networking.hostName = "services";
}

{ lib, config, ... }:

let cfg = config.roles.grafana;
in {
  options.roles.grafana = {
    enable = lib.mkEnableOption "Enable grafana role";
  };

  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;
      settings = {
        server = {
          root_url = "https://grafana.madloba.org/";
          domain = "grafana.madloba.org";
        };
        analytics.reporting_enabled = false;
      };
    };

    security.acme.certs."grafana.madloba.org" = { group = "nginx"; };

    services.nginx = {
      enable = true;

      virtualHosts."grafana.madloba.org" = {
        forceSSL = true;
        sslCertificate = "${
            config.security.acme.certs."grafana.madloba.org".directory
          }/fullchain.pem";
        sslCertificateKey = "${
            config.security.acme.certs."grafana.madloba.org".directory
          }/key.pem";

        locations."/" = {
          proxyPass =
            "http://${config.services.grafana.settings.server.http_addr}:${
              toString config.services.grafana.settings.server.http_port
            }";
          proxyWebsockets = true;
        };
        extraConfig = ''
          access_log /var/log/nginx/grafana.madloba.org-access.log json_combined;
          error_log /var/log/nginx/grafana.madloba.org-error.log;
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    custom.proxmox-backup.jobs.daily = {
      paths = [{
        name = "grafana";
        path = config.services.grafana.dataDir;
      }];
    };
  };
}

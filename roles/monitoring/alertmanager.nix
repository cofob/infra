{ lib, config, pkgs, ... }:

let cfg = config.roles.monitoring.alertmanager;
in {
  options.roles.monitoring.alertmanager = {
    enable = lib.mkEnableOption "Enable AlertManager role";
  };

  config = lib.mkIf cfg.enable {
    age.secrets.credentials-alertmanager-telegram-token = {
      file = "${pkgs.secrets}/credentials/alertmanager/telegram-token.age";
      mode = "0444";
    };

    services.prometheus.alertmanager = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9092;
      webExternalUrl = "https://alertmanager.madloba.org/";
      configuration = {
        global = { resolve_timeout = "5m"; };

        # templates = [ "${./templates}/*.tmpl" ];

        route = {
          group_by = [ "alertname" ];
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "1h";
          receiver = "telegram";
          routes = [
            {
              matchers = [ ''nosend="true"'' ];
              receiver = "null";
            }
            {
              matchers = [ ''nosend="false"'' ];
              routes = [{
                matchers = [ ''noresolved="true"'' ];
                receiver = "telegram-notice";
              }];
            }
          ];
        };

        receivers = let
          telegram-default = {
            bot_token_file =
              config.age.secrets.credentials-alertmanager-telegram-token.path;
            chat_id = -4771900145;
            message = ''
              {{ range .Alerts }}
              ⚠️ <b>Alert</b>: {{ .Annotations.summary }}
              📔 <b>Description</b>: {{ .Annotations.description }}
              📍 <b>Instance</b>: {{ .Labels.instance }}
              🛑 <b>Severity</b>: {{ .Labels.severity }}
              📊 <b>Status</b>: {{ .Status }}
              #{{ .Labels.alertname }}
              {{ end }}
            '';
          };
        in [
          { name = "null"; }
          {
            name = "telegram";
            telegram_configs = [ telegram-default ];
          }
          {
            name = "telegram-notice";
            telegram_configs =
              [ (telegram-default // { send_resolved = false; }) ];
          }
        ];
      };
    };

    age.secrets.credentials-alertmanager-nginx-read = {
      file = "${pkgs.secrets}/credentials/alertmanager/nginx-read.age";
      owner = "nginx";
      group = "nginx";
    };

    security.acme.certs."alertmanager.madloba.org" = { group = "nginx"; };

    services.nginx = {
      enable = true;

      virtualHosts."alertmanager.madloba.org" = {
        forceSSL = true;
        sslCertificate = "${
            config.security.acme.certs."alertmanager.madloba.org".directory
          }/fullchain.pem";
        sslCertificateKey = "${
            config.security.acme.certs."alertmanager.madloba.org".directory
          }/key.pem";

        locations."/" = {
          proxyPass =
            "http://${config.services.prometheus.alertmanager.listenAddress}:${
              toString config.services.prometheus.alertmanager.port
            }";
          basicAuthFile =
            config.age.secrets.credentials-alertmanager-nginx-read.path;
        };
        extraConfig = ''
          access_log /var/log/nginx/alertmanager.madloba.org-access.log json_combined;
          error_log /var/log/nginx/alertmanager.madloba.org-error.log;
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}

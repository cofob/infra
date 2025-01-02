{ lib, config, pkgs, ... }:

let cfg = config.roles.monitoring.loki;
in {
  options.roles.monitoring.loki = {
    enable = lib.mkEnableOption "Enable loki role";
  };

  config = lib.mkIf cfg.enable {
    age.secrets.credentials-loki-variables.file =
      "${pkgs.secrets}/credentials/loki/variables.age";
    age.secrets.credentials-loki-prometheus-write-password = {
      file = "${pkgs.secrets}/credentials/prometheus/write-password.age";
      owner = "loki";
      group = "loki";
    };

    services.loki = {
      enable = true;

      extraFlags = [ "-config.expand-env=true" ];

      configuration = {
        auth_enabled = false;

        server = {
          log_level = "info";
          http_listen_port = 3100;
          grpc_listen_port = 9095;
        };

        storage_config = {
          aws = {
            endpoint = "\${AWS_ENDPOINT}";
            region = "\${AWS_REGION}";
            bucketnames = "\${AWS_BUCKET}";
            access_key_id = "\${AWS_ACCESS_KEY_ID}";
            secret_access_key = "\${AWS_SECRET_ACCESS_KEY}";
          };
        };

        ingester = { chunk_encoding = "zstd"; };

        common = {
          path_prefix = "/var/lib/loki";
          replication_factor = 1;
          ring = { kvstore = { store = "inmemory"; }; };
        };

        # memberlist = {
        #   join_members = [
        #     "loki-1"
        #     "loki-2"
        #   ];
        # };

        schema_config = {
          configs = [{
            from = "2024-12-21";
            store = "tsdb";
            object_store = "aws";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];
        };

        ruler = {
          alertmanager_url = "https://alertmanager.madloba.org";
          alertmanager_client = {
            basic_auth_username = "read";
            basic_auth_password = "\${AM_PASSWORD}";
          };
          enable_alertmanager_v2 = true;
          remote_write = {
            enabled = true;
            clients.main = {
              url = "https://prometheus.madloba.org/api/v1/write";
              basic_auth.username = "write";
              basic_auth.password_file =
                config.age.secrets.credentials-loki-prometheus-write-password.path;
            };
          };
          storage = {
            type = "local";
            local = { directory = "${./rules}"; };
          };
        };

        frontend = { encoding = "protobuf"; };

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          compaction_interval = "5m";
          retention_enabled = true;
          # Delete marked for deletion chunks after 2 hours
          retention_delete_delay = "2h";
          delete_request_store = "aws";
        };

        limits_config = {
          retention_period = "180d";
          reject_old_samples = true;
          reject_old_samples_max_age = "24h";
          retention_stream = [{
            selector = ''{job="nginx"}'';
            priority = 1;
            period = "7d";
          }];

          ingestion_rate_mb = 15;

          allow_structured_metadata = true;
        };

        analytics = {
          reporting_enabled = false;
          usage_stats_url = "https://definetely.disabled.local";
        };
      };
    };

    systemd.services.loki.serviceConfig.EnvironmentFile =
      config.age.secrets.credentials-loki-variables.path;

    age.secrets.credentials-loki-nginx-read = {
      file = "${pkgs.secrets}/credentials/loki/nginx-read.age";
      owner = "nginx";
      group = "nginx";
    };
    age.secrets.credentials-loki-nginx-write = {
      file = "${pkgs.secrets}/credentials/loki/nginx-write.age";
      owner = "nginx";
      group = "nginx";
    };

    security.acme.certs."loki.madloba.org" = { group = "nginx"; };

    services.nginx = {
      enable = true;

      virtualHosts."loki.madloba.org" = {
        forceSSL = true;
        sslCertificate = "${
            config.security.acme.certs."loki.madloba.org".directory
          }/fullchain.pem";
        sslCertificateKey =
          "${config.security.acme.certs."loki.madloba.org".directory}/key.pem";

        locations."/loki/api/v1/push" = {
          proxyPass = "http://127.0.0.1:3100/loki/api/v1/push";
          basicAuthFile = config.age.secrets.credentials-loki-nginx-write.path;
        };
        locations."/" = {
          proxyPass = "http://127.0.0.1:3100";
          proxyWebsockets = true;
          basicAuthFile = config.age.secrets.credentials-loki-nginx-read.path;
          extraConfig = ''
            proxy_read_timeout 1200;
          '';
        };
        extraConfig = ''
          access_log /var/log/nginx/loki.madloba.org-access.log json_combined;
          error_log /var/log/nginx/loki.madloba.org-error.log;
        '';
      };

      virtualHosts."${config.meta.ip}" = {
        listen = [{
          addr = "0.0.0.0";
          port = 9106;
        }];

        locations."= /metrics" = {
          proxyPass = "http://127.0.0.1:3100";
          extraConfig = ''
            allow ${pkgs.crossSystem.systemIPs.monitoring};
            deny all;
          '';
        };

        extraConfig = ''
          access_log /var/log/nginx/loki-metrics-access.log json_combined;
          error_log /var/log/nginx/loki-metrics-error.log;
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
      9106 # loki metrics
      # # loki
      # 3100
      # 9095
      # # memberlist
      # 7946
    ];
  };
}

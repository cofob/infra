{ config, lib, pkgs, ... }:

let cfg = config.custom.monitoring;
in {
  options.custom.monitoring = {
    enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable monitoring";
    };

    enablePromtail = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable promtail";
    };

    enableNodeExporter = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable node exporter";
    };

    enableSystemdExporter = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable systemd exporter";
    };

    enableCAdvisor = lib.mkOption {
      default = config.virtualisation.docker.enable;
      type = lib.types.bool;
      description = "Enable cAdvisor";
    };

    enableNginxExporters = lib.mkOption {
      default = config.services.nginx.enable;
      type = lib.types.bool;
      description = "Enable nginx exporter";
    };

    enablePostgresExporter = lib.mkOption {
      default = config.services.postgresql.enable;
      type = lib.types.bool;
      description = "Enable postgres exporter";
    };

    enableSyslogCollector = lib.mkOption {
      default = config.services.rsyslogd.enable;
      type = lib.types.bool;
      description = "Enable syslog log collector";
    };

    monitorIp = lib.mkOption {
      default = pkgs.crossSystem.systemIPs.monitoring;
      type = lib.types.str;
      description = "IP address of the monitoring server";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf cfg.enablePromtail {
      age.secrets.credentials-loki-write-password = {
        file = "${pkgs.secrets}/credentials/loki/write-password.age";
        owner = "promtail";
        group = "promtail";
      };

      services.promtail = {
        enable = true;
        configuration = {
          server = {
            http_listen_port = 9080;
            grpc_listen_port = 0;
          };
          clients = [{
            url = "https://loki.madloba.org/loki/api/v1/push";
            basic_auth = {
              username = "write";
              password_file =
                config.age.secrets.credentials-loki-write-password.path;
            };
          }];
          scrape_configs = [{
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = config.networking.hostName;
              };
            };
            relabel_configs = [{
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }];
          }] ++ (lib.optional cfg.enableNginxExporters {
            job_name = "nginx";
            static_configs = [
              {
                targets = [ "localhost" ];
                labels = {
                  job = "nginx";
                  __path__ = "/var/log/nginx/*access.log";
                  host = config.networking.hostName;
                  type = "access";
                };
              }
              {
                targets = [ "localhost" ];
                labels = {
                  job = "nginx";
                  __path__ = "/var/log/nginx/*error.log";
                  host = config.networking.hostName;
                  type = "error";
                };
              }
            ];
            pipeline_stages = [
              {
                match = {
                  selector = ''{job="nginx", type="access"}'';
                  stages = [
                    {
                      json = {
                        expressions = {
                          time_local = "";
                          request = "";
                        };
                      };
                    }
                    {
                      timestamp = {
                        source = "time_local";
                        format = "02/Jan/2006:15:04:05 -0700";
                      };
                    }
                    {
                      regex = {
                        expression =
                          "^(?P<method>[^ ]*) (?P<request_url>[^ ]*) (?P<http_version>[^ ]*)$";
                        source = "request";
                      };
                    }
                    {
                      structured_metadata = {
                        method = null;
                        request_url = null;
                        http_version = null;
                      };
                    }
                  ];
                };
              }
              {
                match = {
                  selector = ''{job="nginx"}'';
                  stages = [
                    {
                      regex = {
                        expression =
                          "/var/log/nginx/(?P<domain>[a-zA-Z.-]+)-(?:access|error)\\.log$";
                        source = "filename";
                      };
                    }
                    { labels = { domain = null; }; }
                  ];
                };
              }
            ];
          });
        };
      };
    })
    (lib.mkIf (cfg.enablePromtail && cfg.enableNginxExporters) {
      # Allow promtail to read nginx logs
      users.users.promtail.extraGroups = [ "nginx" ];
      systemd.services.promtail.unitConfig.After = "nginx.service";
      systemd.services.promtail.serviceConfig.ReadWritePaths = "/var/log/nginx";
    })
    (lib.mkIf (cfg.enablePromtail && cfg.enableSyslogCollector) {
      services.promtail.configuration.scrape_configs = [{
        job_name = "syslog";
        syslog = {
          listen_address = "0.0.0.0:1514";
          labels = {
            job = "syslog";
            local_host = config.networking.hostName;
          };
        };
        relabel_configs = [
          {
            source_labels = [ "__syslog_message_hostname" ];
            target_label = "host";
          }
          {
            source_labels = [ "__syslog_message_app_name" ];
            target_label = "app";
          }
        ];
        pipeline_stages = [{
          match = {
            selector = ''{job="syslog",app="filterlog"}'';
            stages = [
              {
                regex = {
                  expression =
                    "^([a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),(?P<interface>[a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),(?P<action>[a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),(?P<ip_version>[a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),(?P<proto>[a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),(?P<src>[a-zA-Z0-9\\.;]*),(?P<dst>[a-zA-Z0-9\\.;]*),([a-zA-Z0-9\\.;]*),(?<dst_port>[a-zA-Z0-9\\.;]*),.*";
                };
              }
              {
                structured_metadata = {
                  interface = null;
                  action = null;
                  ip_version = null;
                  proto = null;
                  src = null;
                  dst = null;
                  dst_port = null;
                };
              }
            ];
          };
        }];
      }];
    })
    (lib.mkIf cfg.enableNodeExporter {
      services.prometheus.exporters.node = {
        enable = true;
        port = 9100;
        enabledCollectors = [ "systemd" ];
      };

      # Allow prometheus to scrape node exporter
      networking.firewall.extraCommands = ''
        iptables -A nixos-fw -p tcp --dport ${
          toString config.services.prometheus.exporters.node.port
        } -s ${cfg.monitorIp} -j ACCEPT
      '';
    })
    (lib.mkIf cfg.enableSystemdExporter {
      services.prometheus.exporters.systemd = {
        enable = true;
        port = 9103;
      };

      # Allow prometheus to scrape systemd exporter
      networking.firewall.extraCommands = ''
        iptables -A nixos-fw -p tcp --dport ${
          toString config.services.prometheus.exporters.systemd.port
        } -s ${cfg.monitorIp} -j ACCEPT
      '';
    })
    (lib.mkIf cfg.enableCAdvisor {
      services.cadvisor = {
        enable = true;
        listenAddress = "0.0.0.0";
        port = 9101;
      };

      # Allow prometheus to scrape cAdvisor
      networking.firewall.extraCommands = ''
        iptables -A nixos-fw -p tcp --dport ${
          toString config.services.cadvisor.port
        } -s ${cfg.monitorIp} -j ACCEPT
      '';
    })
    (lib.mkIf cfg.enableNginxExporters {
      services.nginx.statusPage = true;

      services.prometheus.exporters.nginx = {
        enable = true;
        port = 9104;
      };

      # Sometimes nginx exporter fails to start on boot, this should fix it
      systemd.services.prometheus-nginx-exporter.serviceConfig.Restart =
        "always";
      systemd.services.prometheus-nginx-exporter.serviceConfig.RestartSec = 5;
      systemd.services.prometheus-nginx-exporter.unitConfig.After =
        lib.mkForce "network.target";
      systemd.services.prometheus-nginx-exporter.unitConfig.Requires =
        lib.mkForce null;

      # Allow prometheus to scrape nginx exporter
      networking.firewall.extraCommands = ''
        iptables -A nixos-fw -p tcp --dport ${
          toString config.services.prometheus.exporters.nginx.port
        } -s ${cfg.monitorIp} -j ACCEPT
      '';
    })
    (lib.mkIf cfg.enablePostgresExporter {
      services.prometheus.exporters.postgres = {
        enable = true;
        port = 9105;
        runAsLocalSuperUser = true;
      };

      # Allow prometheus to scrape postgres exporter
      networking.firewall.extraCommands = ''
        iptables -A nixos-fw -p tcp --dport ${
          toString config.services.prometheus.exporters.postgres.port
        } -s ${cfg.monitorIp} -j ACCEPT
      '';
    })
  ]);
}

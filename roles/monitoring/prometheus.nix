{ lib, config, pkgs, ... }:

let
  cfg = config.roles.prometheus;
  exporterHosts = port: configName:
    map (n: "${n}:${port}") (pkgs.crossSystem.filterSystemNamesWithDomain
      (name: system-config: system-config.custom.monitoring."${configName}"));
  node-exporter-hosts = exporterHosts "9100" "enableNodeExporter";
  cadvisor-hosts = exporterHosts "9101" "enableCAdvisor";
  systemd-exporter-hosts = exporterHosts "9103" "enableSystemdExporter";
  nginx-exporter-hosts = exporterHosts "9104" "enableNginxExporters";
  postgres-hosts = exporterHosts "9105" "enablePostgresExporter";
in {
  options.roles.prometheus = {
    enable = lib.mkEnableOption "Enable prometheus role";
  };

  config = lib.mkIf cfg.enable {
    age.secrets.credentials-prometheus-alertmanager-read-password = {
      file = "${pkgs.secrets}/credentials/alertmanager/read-password.age";
      owner = "prometheus";
      group = "prometheus";
    };

    services.prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      extraFlags = [
        "--web.external-url=https://prometheus.madloba.org/"
        "--web.enable-remote-write-receiver"
        "--storage.tsdb.retention.time=1y"
        "--log.level=warn"
      ];
      globalConfig.scrape_interval = "15s";
      globalConfig.evaluation_interval = "15s";
      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [{ targets = [ "localhost:9090" ]; }];
        }
        {
          job_name = "pushgateway";
          honor_labels = true;
          metrics_path = "/push/metrics";
          static_configs = [{ targets = [ "localhost:9091" ]; }];
        }
        {
          job_name = "loki";
          static_configs = [{ targets = [ "loki.madloba.org:9106" ]; }];
        }
        {
          job_name = "node";
          static_configs = [{ targets = node-exporter-hosts; }];
        }
        {
          job_name = "systemd";
          static_configs = [{ targets = systemd-exporter-hosts; }];
        }
        {
          job_name = "nginx";
          static_configs = [{ targets = nginx-exporter-hosts; }];
        }
        {
          job_name = "cadvisor";
          static_configs = [{ targets = cadvisor-hosts; }];
        }
        {
          job_name = "postgres";
          static_configs = [{ targets = postgres-hosts; }];
        }
      ];
      alertmanagers = [{
        basic_auth = {
          username = "read";
          password_file =
            config.age.secrets.credentials-prometheus-alertmanager-read-password.path;
        };
        scheme = "https";
        static_configs = [{ targets = [ "alertmanager.madloba.org" ]; }];
      }];
      rules = [''
        groups:
        - name: node_down
          rules:
          - alert: NodeDown
            expr: up{job="node"} == 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Node is down"
              description: "Node {{ $labels.instance }} has been down for more than 5 minutes."
        - name: node_low_disk_space
          rules:
          - alert: NodeLowDiskSpace
            expr: (node_filesystem_free_bytes{fstype!~"tmpfs|ramfs|devtmpfs"} / node_filesystem_size_bytes{fstype!~"tmpfs|ramfs|devtmpfs"}) * 100 < 10
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "Node {{ $labels.instance }} has low disk space"
              description: "Filesystem {{ $labels.mountpoint }} on instance {{ $labels.instance }} has less than 10% ({{ $value }}) free space."
        - name: node_critical_low_disk_space
          rules:
          - alert: NodeCriticalLowDiskSpace
            expr: (node_filesystem_free_bytes{fstype!~"tmpfs|ramfs|devtmpfs"} / node_filesystem_size_bytes{fstype!~"tmpfs|ramfs|devtmpfs"}) * 100 < 5
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Node {{ $labels.instance }} has dangerously low disk space"
              description: "Filesystem {{ $labels.mountpoint }} on instance {{ $labels.instance }} has less than 5% ({{ $value }}) free space."
        - name: node_high_cpu_usage
          rules:
          - alert: NodeHighCpuUsage
            expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
            for: 10m
            labels:
              severity: critical
            annotations:
              summary: "High CPU usage on {{ $labels.instance }}"
              description: "CPU usage is above 90% ({{ $value }}) for more than 10 minutes on instance {{ $labels.instance }}."
        - name: node_high_memory_usage
          rules:
          - alert: NodeHighMemoryUsage
            expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 70
            for: 10m
            labels:
              severity: critical
            annotations:
              summary: "High memory usage on {{ $labels.instance }}"
              description: "Memory usage is above 70% ({{ $value }}) for more than 10 minutes on instance {{ $labels.instance }}."
        - name: node_high_receive_network_usage
          rules:
          - alert: NodeHighReceiveNetworkUsage
            expr: sum by (instance) (irate(node_network_receive_bytes_total{job="node",device="ens18"}[1m])/125000) > 200
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "High receive network usage on {{ $labels.instance }}"
              description: "Receive network usage is above 200 Mbits/sec ({{ $value }}) for more than 5 minutes on instance {{ $labels.instance }}."
        - name: node_high_transmit_network_usage
          rules:
          - alert: NodeHighTransmitNetworkUsage
            expr: sum by (instance) (irate(node_network_transmit_bytes_total{job="node",device="ens18"}[1m])/125000) > 200
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "High transmit network usage on {{ $labels.instance }}"
              description: "Transmit network usage is above 200 Mbits/sec ({{ $value }}) for more than 5 minutes on instance {{ $labels.instance }}."
        - name: systemd_service_failures
          rules:
          - alert: SystemdServiceFailure
            expr: systemd_unit_state{state=~"failed"} == 1
            for: 1m
            labels:
              severity: critical
            annotations:
              summary: "Systemd service {{ $labels.name }} has failed on {{ $labels.instance }}"
              description: "The systemd service '{{ $labels.name }}' is in a {{ $labels.state }} state on instance {{ $labels.instance }}."
        - name: nginx_high_connections
          rules:
          - alert: HighNginxConnections
            expr: nginx_connections_active > 6000
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "High number of active NGINX connections on {{ $labels.instance }}"
              description: "The number of active NGINX connections is above 6000 ({{ $value }}) for more than 5 minutes on instance {{ $labels.instance }}."
        - name: nginx_high_requests
          rules:
          - alert: HighNginxRequests
            expr: sum by (domain) (nginx:requests:rate1m) > 100
            labels:
              severity: warning
            annotations:
              summary: "High number of NGINX requests to {{ $labels.domain }}"
              description: "The number of NGINX requests is above 100 per second ({{ $value }}) on domain {{ $labels.domain }}."
        - name: nginx_high_errors
          rules:
          - alert: HighNginxErrors
            expr: sum by (domain) (nginx:errors:rate1m) > 30
            labels:
              severity: warning
            annotations:
              summary: "High number of NGINX errors on {{ $labels.domain }}"
              description: "The number of NGINX errors is above 30 per minute ({{ $value }}) in file {{ $labels.domain }}."
        - name: prometheus_failed_targets
          rules:
          - alert: PrometheusFailedTargets
            expr: count(up == 0) by (job) > 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Prometheus has failed targets"
              description: "There are {{ $value }} failed targets for the job {{ $labels.job }}."
      ''];
    };

    services.prometheus.pushgateway = {
      enable = true;
      web.listen-address = "127.0.0.1:9091";
      web.external-url = "https://prometheus.madloba.org/push/";
    };

    age.secrets.credentials-prometheus-nginx-read = {
      file = "${pkgs.secrets}/credentials/prometheus/nginx-read.age";
      owner = "nginx";
      group = "nginx";
    };
    age.secrets.credentials-prometheus-nginx-write = {
      file = "${pkgs.secrets}/credentials/prometheus/nginx-write.age";
      owner = "nginx";
      group = "nginx";
    };

    security.acme.certs."prometheus.madloba.org" = { group = "nginx"; };

    services.nginx = {
      enable = true;

      virtualHosts."prometheus.madloba.org" = {
        forceSSL = true;
        sslCertificate = "${
            config.security.acme.certs."prometheus.madloba.org".directory
          }/fullchain.pem";
        sslCertificateKey = "${
            config.security.acme.certs."prometheus.madloba.org".directory
          }/key.pem";

        locations."/push/" = {
          proxyPass =
            "http://${config.services.prometheus.pushgateway.web.listen-address}";
          basicAuthFile =
            config.age.secrets.credentials-prometheus-nginx-write.path;
        };
        locations."/api/v1/write" = {
          proxyPass = "http://${config.services.prometheus.listenAddress}:${
              toString config.services.prometheus.port
            }";
          basicAuthFile =
            config.age.secrets.credentials-prometheus-nginx-write.path;
        };
        locations."/" = {
          proxyPass = "http://${config.services.prometheus.listenAddress}:${
              toString config.services.prometheus.port
            }";
          basicAuthFile =
            config.age.secrets.credentials-prometheus-nginx-read.path;
        };
        extraConfig = ''
          access_log /var/log/nginx/prometheus.madloba.org-access.log json_combined;
          error_log /var/log/nginx/prometheus.madloba.org-error.log;
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    custom.proxmox-backup.jobs.daily = {
      paths = [{
        name = "prometheus";
        path = "/var/lib/prometheus2";
      }];
    };
  };
}

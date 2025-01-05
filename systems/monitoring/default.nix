{ ... }:

{
  roles.monitoring.prometheus.enable = true;
  roles.monitoring.alertmanager.enable = true;
  roles.monitoring.loki.enable = true;
  roles.monitoring.grafana.enable = true;
  roles.monitoring.syslog.enable = true;

  networking.hostName = "monitoring";
}

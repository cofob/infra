{ ... }:

{
  roles.prometheus.enable = true;
  roles.alertmanager.enable = true;
  roles.loki.enable = true;
  roles.grafana.enable = true;
  roles.syslog.enable = true;

  meta.ip = "10.190.0.3";
  networking.hostName = "monitoring";
}

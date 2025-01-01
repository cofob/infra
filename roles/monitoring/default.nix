{ ... }:

{
  imports =
    [ ./prometheus.nix ./loki ./alertmanager.nix ./grafana.nix ./syslog.nix ];
}

{ config, lib, ... }:

let cfg = config.roles.monitoring.syslog;
in {
  options.roles.monitoring.syslog = {
    enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Enable syslog server role.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.rsyslogd = {
      enable = true;
      defaultConfig = lib.mkForce ''
        # https://www.rsyslog.com/doc/v8-stable/concepts/multi_ruleset.html#split-local-and-remote-logging
        ruleset(name="remote"){
          # https://www.rsyslog.com/doc/v8-stable/configuration/modules/omfwd.html
          # https://grafana.com/docs/loki/latest/clients/promtail/scraping/#rsyslog-output-configuration
          action(type="omfwd" Target="localhost" Port="1514" Protocol="tcp" Template="RSYSLOG_SyslogProtocol23Format" TCP_Framing="octet-counted")
        }

        # https://www.rsyslog.com/doc/v8-stable/configuration/modules/imudp.html
        module(load="imudp")
        input(type="imudp" port="514" ruleset="remote")

        # https://www.rsyslog.com/doc/v8-stable/configuration/modules/imtcp.html
        module(load="imtcp")
        input(type="imtcp" port="514" ruleset="remote")
      '';
    };

    networking.firewall.allowedUDPPorts = [ 514 ];
    networking.firewall.allowedTCPPorts = [ 514 ];
  };
}

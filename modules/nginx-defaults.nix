{ lib, config, pkgs, ... }:

let cfg = config.custom.nginx-defaults;
in {
  options.custom.nginx-defaults = {
    enable = lib.mkOption {
      default = config.services.nginx.enable;
      type = lib.types.bool;
      description = "Enable nginx recommended options";
    };
    recommendedOptions.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable nginx recommended options";
    };
    logrotate.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable nginx log rotation";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    ({ services.nginx.package = lib.mkDefault pkgs.nginx-custom; })
    (lib.mkIf cfg.recommendedOptions.enable {
      services.nginx = {
        recommendedZstdSettings = true;
        recommendedProxySettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;
        recommendedBrotliSettings = true;
        commonHttpConfig = ''
          log_format json_combined escape=json
            '{'
              '"time_local":"$time_local",'
              '"remote_addr":"$remote_addr",'
              '"remote_user":"$remote_user",'
              '"request":"$request",'
              '"status": "$status",'
              '"body_bytes_sent":"$body_bytes_sent",'
              '"request_time":"$request_time",'
              '"http_referrer":"$http_referer",'
              '"http_user_agent":"$http_user_agent"'
            '}';
        '';
      };
    })
    (lib.mkIf cfg.logrotate.enable {
      services.logrotate = {
        enable = true;
        settings.nginx = lib.mkForce {
          files = "/var/log/nginx/*.log";
          frequency = "daily";
          su = "${config.services.nginx.user} ${config.services.nginx.group}";
          rotate = 3; # 3 days
          compress = true;
          delaycompress = true;
          postrotate =
            "[ ! -f /var/run/nginx/nginx.pid ] || kill -USR1 `cat /var/run/nginx/nginx.pid`";
        };
      };
    })
  ]);
}

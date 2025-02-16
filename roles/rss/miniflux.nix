{ lib, config, pkgs, ... }:

let cfg = config.roles.rss.miniflux;
in {
  options.roles.rss.miniflux = {
    enable = lib.mkEnableOption "Enable miniflux role";
  };

  config = lib.mkIf cfg.enable {
    age.secrets.credentials-miniflux-admin.file =
      "${pkgs.secrets}/credentials/miniflux/admin.age";

    services.miniflux = {
      enable = true;
      config = { LISTEN_ADDR = "localhost:8572"; };
      adminCredentialsFile = config.age.secrets.credentials-miniflux-admin.path;
    };
  };
}

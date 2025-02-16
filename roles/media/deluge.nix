{ lib, config, ... }:

let cfg = config.roles.media.deluge;
in {
  options.roles.media.deluge = {
    enable = lib.mkEnableOption "Enable deluge role";
  };

  config = lib.mkIf cfg.enable {
    services.deluge = {
      enable = true;
      web.enable = true;
    };

    networking.firewall.allowedTCPPorts = [ 6881 ];
  };
}

{ lib, config, pkgs, ... }:

let cfg = config.roles.media.lidarr;
in {
  options.roles.media.lidarr = {
    enable = lib.mkEnableOption "Enable Lidarr, a Usenet/BitTorrent music downloader role";
  };

  config = lib.mkIf cfg.enable {
    services.lidarr = {
      enable = true;
    };

    age.secrets.credentials-aria2-rpc-secret = {
      file = "${pkgs.secrets}/credentials/aria2/rpc-secret.age";
      owner = "aria2";
      group = "aria2";
    };

    services.aria2 = {
      enable = true;
      rpcSecretFile = config.age.secrets.credentials-aria2-rpc-secret.path;
    };
  };
}

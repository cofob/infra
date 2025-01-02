{ lib, config, pkgs, ... }:

let cfg = config.roles.utility.cf-ts-dnssync;
in {
  options.roles.utility.cf-ts-dnssync = {
    enable = lib.mkEnableOption "Enable cloudflare-tailscale DNS sync role";
  };

  config = lib.mkIf cfg.enable {
    age.secrets.credentials-cf-ts-dnssync.file =
      "${pkgs.secrets}/credentials/cf-ts-dnssync.age";

    virtualisation.podman.enable = true;

    systemd.services."cf-ts-dnssync" = {
      enable = true;
      description = "Cloudflare Tailscale DNS sync";
      after = [ "network.target" ];
      serviceConfig.Type = "oneshot";
      path = [ pkgs.podman ];
      environment = {
        CONTAINER_TAG =
          "ghcr.io/marc1307/tailscale-cloudflare-dnssync@sha256:d5f1698f13626a9610c2631553ae74ea4eb75ae33bc636fb980a12cf0c09bc21";
        CONTAINER_NAME = "cf-ts-dnssync";
        ENV_FILE = "${config.age.secrets.credentials-cf-ts-dnssync.path}";
      };
      script = ''
        # Pull the image if it doesn't exist
        podman image inspect "$CONTAINER_TAG" &> /dev/null || podman pull "$CONTAINER_TAG"
        # Check if the container exists and remove it
        podman ps -a --format '{{.Names}}' | grep "$CONTAINER_NAME" &> /dev/null && podman rm -f "$CONTAINER_NAME"
        # Run the container
        podman run \
          --name "$CONTAINER_NAME" \
          --rm \
          --env-file "$ENV_FILE" \
          "$CONTAINER_TAG"
      '';
    };

    systemd.timers."cf-ts-dnssync" = {
      enable = true;
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };
  };
}

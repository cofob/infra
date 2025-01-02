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
          "ghcr.io/cofob/tailscale-cloudflare-dnssync:main@sha256:cb0791a44dd29a730a52c9b0fa36afe08ff48cbeef6837a03037b1f6f212c0a8";
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

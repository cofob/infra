{ lib, config, pkgs, ... }:

let cfg = config.roles.utility.cf-opn-dnssync;
in {
  options.roles.utility.cf-opn-dnssync = {
    enable = lib.mkEnableOption "Enable Cloudflare-OPNsense DNS sync role";
  };

  config = lib.mkIf cfg.enable {
    age.secrets.credentials-cf-opn-dnssync.file =
      "${pkgs.secrets}/credentials/cf-opn-dnssync.age";

    virtualisation.podman.enable = true;

    systemd.services."cf-opn-dnssync" = {
      enable = true;
      description = "Cloudflare OPNsense DNS sync";
      after = [ "network.target" ];
      serviceConfig.Type = "oneshot";
      path = [ pkgs.podman ];
      environment = {
        CONTAINER_TAG =
          "ghcr.io/cofob/opnsense-lease-cf-sync@sha256:0c168a0988cf04418c8d21d95414c60555ef7acc2646131b19b8dd4aa2f06e03";
        CONTAINER_NAME = "cf-opn-dnssync";
        ENV_FILE = "${config.age.secrets.credentials-cf-opn-dnssync.path}";
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

    systemd.timers."cf-opn-dnssync" = {
      enable = true;
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };
  };
}

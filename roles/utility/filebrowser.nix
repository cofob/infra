{ lib, config, pkgs, ... }:

let
  cfg = config.roles.utility.filebrowser;
  config-file = pkgs.writeText "filebrowser.json" (builtins.toJSON {
    "port" = 8080;
    "baseURL" = "/";
    "address" = "0.0.0.0";
    "log" = "stdout";
    "database" = "/database/filebrowser.db";
    "root" = "/srv";
  });
in {
  options.roles.utility.filebrowser = {
    enable = lib.mkEnableOption "Enable web file browser role";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman.enable = true;

    systemd.services."filebrowser" = {
      enable = true;
      description = "Web file browser";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.podman pkgs.coreutils ];
      environment = {
        CONTAINER_TAG =
          "docker.io/filebrowser/filebrowser:latest@sha256:66b9cde27042b594c50944a26d3e512e9f75fe10c467aad897acf1d768cc98a8";
        CONTAINER_NAME = "filebrowser";
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
          -v /:/srv \
          -v filebrowser_db:/database \
          -v ${config-file}:/.filebrowser.json:ro \
          -p 127.0.0.1:8080:8080 \
          -u $(id -u):$(id -g) \
          "$CONTAINER_TAG"
      '';
    };
  };
}

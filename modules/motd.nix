{ config, lib, pkgs, ... }:

let cfg = config.custom.motd;
in {
  options.custom.motd = {
    enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable MOTD";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.rust-motd = {
      enable = true;
      settings = {
        banner.color = "white";
        banner.command = pkgs.writeShellScript "rust-motd" ''
          #!/usr/bin/env bash
          echo "Hello! Host ${config.networking.hostName} is managed by NixOS."
          echo "Have a nice day!"
        '';
        uptime.prefix = "Uptime:";
        filesystems.root = "/";
        memory.swap_pos = "below";
      };
      order = [ "banner" "uptime" "filesystems" "memory" ];
    };
  };
}

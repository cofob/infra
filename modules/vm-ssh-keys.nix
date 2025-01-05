{ lib, config, pkgs, ... }:

with lib;

let cfg = config.custom.vm-ssh-keys;
in {
  options = {
    custom.vm-ssh-keys = {
      enable = mkEnableOption "Whether to enable vm ssh keys provision";

      vms = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            file = mkOption {
              type = types.str;
              description = "Path to the age file";
            };
          };
        });
      };
    };
  };

  config = let
    ageObj = mapAttrs (name: conf: {
      name = "ssh-keys/${name}/key";
      value = {
        file = conf.file or "${pkgs.secrets}/ssh-keys/${name}.age";
        mode = "0440";
      };
    }) cfg.vms;
  in mkIf cfg.enable {
    systemd.services.vm-ssh-keys = {
      description = "Copy SSH keys for VMs";
      before = [ "nixvirt.service" ];
      wantedBy = [ "nixvirt.service" ];
      restartTriggers = [ pkgs.secrets ];
      script = ''
        cp -r /run/agenix/ssh-keys/* /var/lib/vm-ssh-keys
        chown -R qemu-libvirtd:qemu-libvirtd /var/lib/vm-ssh-keys/*
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "vm-ssh-keys";
      };
    };

    age.secrets =
      (builtins.listToAttrs (map (key: getAttr key ageObj) (attrNames ageObj)));
  };
}

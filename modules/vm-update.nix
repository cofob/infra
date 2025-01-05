{ lib, config, pkgs, ... }:

with lib;

let cfg = config.custom.vm-update;
in {
  options = {
    custom.vm-update = {
      enable = mkEnableOption "Whether to enable vm update with Qemu GA";

      connection = mkOption {
        type = types.str;
        default = "qemu:///system";
        description = "Libvirt connection URI";
      };

      vms = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            system = mkOption {
              type = types.attrs;
              description = "NixOS system configuration";
            };
          };
        });
      };
    };
  };

  config = let
    obj = mapAttrs (name: conf:
      let toplevel = conf.system.config.system.build.toplevel;
      in {
        name = "update-vm-${name}";
        value = {
          description = "Update ${name} configuration";
          after = [ "libvirtd.service" ];
          wants = [ "libvirtd.service" ];
          wantedBy = [ "multi-user.target" ];
          path = with pkgs; [ libvirt ];
          restartTriggers = [ toplevel ];
          environment = {
            domain = name;
            connection = cfg.connection;
            command = builtins.toJSON {
              execute = "guest-exec";
              arguments = {
                path = "${toplevel}/bin/switch-to-configuration";
                arg = [ "switch" ];
                capture-output = true;
              };
            };
          };
          script = ''
            virsh -c qemu:///system qemu-agent-command "$domain" "$command" || true
          '';
          serviceConfig.Type = "oneshot";
        };
      }) cfg.vms;
  in mkIf cfg.enable ({
    systemd.services =
      (builtins.listToAttrs (map (key: getAttr key obj) (attrNames obj)));
  });
}

{ lib, config, pkgs, ... }:

with lib;

let cfg = config.custom.vm-disks;
in {
  options = {
    custom.vm-disks = {
      enable = mkEnableOption "Whether to enable vm disks generation";

      dataDir = mkOption {
        type = types.path;
        default = "/data/vm/disks";
        description = "Directory to store vm disks";
      };

      disks = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            size = mkOption {
              type = types.str;
              default = "10G";
              description = "Disk size";
            };

            chown = mkOption {
              type = types.str;
              default = "qemu-libvirtd:qemu-libvirtd";
              description = "Chown";
            };

            mode = mkOption {
              type = types.str;
              default = "0600";
              description = "Mode";
            };
          };
        });
      };
    };
  };

  config = let
    obj = mapAttrs (name: conf: {
      name = "generate-vm-disk-${name}";
      value = {
        description = "Generate ${name} disk image";
        before = [ "libvirtd.service" "nixvirt.service" ];
        requiredBy = [ "nixvirt.service" ];
        path = with pkgs; [ coreutils qemu-utils e2fsprogs ];
        environment = {
          size = conf.size;
          name = name;
          disk_path = "${cfg.dataDir}/${name}.qcow2";
          chown = conf.chown;
          mode = conf.mode;
        };
        script = ''
          # If the file already exists, do nothing
          if [ -e "$disk_path" ]; then
            exit 0
          fi

          echo "Generating empty disk image $name"
          temp="$RUNTIME_DIRECTORY/$name.raw"
          qemu-img create -f raw "$temp" "$size"
          mkfs.ext4 -L nixos "$temp"
          qemu-img convert -f raw -O qcow2 "$temp" "$disk_path"
          rm "$temp"
          chown "$chown" "$disk_path"
          chmod "$mode" "$disk_path"
          echo "Generated empty disk image $name"
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          RuntimeDirectory = "vm-disks/${name}";
        };
      };
    }) cfg.disks;
  in mkIf cfg.enable ({
    systemd.services =
      (builtins.listToAttrs (map (key: getAttr key obj) (attrNames obj)));
  });
}

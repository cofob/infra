{ self, pkgs, ... }:

{
  # Enable nixvirt and libvirt
  virtualisation.libvirt.enable = true;

  # Run libvirtd as non-root
  virtualisation.libvirtd.qemu.runAsRoot = false;

  # Allow management of libvirtd over SSH
  virtualisation.libvirtd.extraConfig = ''
    unix_sock_rw_perms = "0770";
    unix_sock_group = "libvirtd"
  '';
  users.users.cofob.extraGroups = [ "libvirtd" ];

  custom.vm-disks = {
    enable = true;
    disks.empty-1.size = "10G";
    disks.empty-2.size = "10G";
  };

  custom.vm-update = {
    enable = true;
    vms.empty-1.system = self.nixosConfigurations.empty;
    vms.empty-2.system = self.nixosConfigurations.empty;
  };

  custom.vm-ssh-keys = {
    enable = true;
    vms.empty-1 = { file = "${pkgs.secrets}/ssh-keys/empty.age"; };
    vms.empty-2 = { file = "${pkgs.secrets}/ssh-keys/empty.age"; };
  };

  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      {
        definition = (import ./empty.nix {
          inherit pkgs;
          libvirtConfig = {
            name = "empty-1";
            uuid = "cf5f8c92-048b-4e58-91ad-c2309bc30c87";
            mac = "52:54:00:cf:5f:8a";
          };
          config = self.nixosConfigurations.empty;
        });
        active = true;
        restart = false;
      }
      {
        definition = (import ./empty.nix {
          inherit pkgs;
          libvirtConfig = {
            name = "empty-2";
            uuid = "57b25ca7-bd6f-45f7-830f-286d25ef0069";
            mac = "52:54:00:cf:5f:8b";
          };
          config = self.nixosConfigurations.empty;
        });
        active = true;
        restart = false;
      }
      {
        definition = ./opnsense.xml;
        active = true;
        restart = false;
      }
      {
        definition = ./services.xml;
        active = true;
        restart = false;
      }
      {
        definition = ./monitoring.xml;
        active = true;
        restart = false;
      }
    ];
  };
}

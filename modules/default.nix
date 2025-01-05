{ agenix, nixvirt, ... }:

{
  imports = [
    agenix.nixosModules.default
    nixvirt.nixosModules.default

    ./common.nix
    ./users.nix
    ./overlays.nix
    ./cross-system.nix

    ./proxmox-backup.nix
    ./motd.nix
    ./monitoring.nix
    ./nginx-defaults.nix
    ./vm-disks.nix
    ./vm-update.nix
    ./vm-ssh-keys.nix
    ./declarative-vm.nix
  ];
}

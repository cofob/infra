{ agenix, nixvirt, ... }:

{
  imports = [
    agenix.nixosModules.default
    nixvirt.nixosModules.default

    ./common.nix
    ./users.nix
    ./overlays.nix
    ./cross-system.nix
    ./meta.nix

    ./proxmox-backup.nix
    ./motd.nix
    ./monitoring.nix
    ./nginx-defaults.nix
  ];
}

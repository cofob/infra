{ agenix, ... }:

{
  imports = [
    agenix.nixosModules.default

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

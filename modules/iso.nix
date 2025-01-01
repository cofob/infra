{ pkgs, modulesPath, lib, self, ... }:

let ssh-keys = import "${self}/ssh-keys.nix";
in {
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.supportedFilesystems =
    lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];

  # Age and GRUB is not needed in the installer
  custom.common.setup-age.enable = false;
  custom.common.setup-grub.enable = false;

  # Allow root login
  custom.common.ssh-defaults.enable = false;
  # Disable MOTD
  custom.motd.enable = false;
  # Disable backups
  custom.common.pbs-defaults.enable = false;

  # Disable added users
  custom.users.enable = false;

  # Disable monitoring
  custom.monitoring.enable = false;

  # Disable WiFi.
  # Conflicts with NetworkManager
  networking.wireless.enable = false;

  # Disable meta module
  meta.enable = false;

  # Enable SSH in the boot process.
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keys = ssh-keys.all-users;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Resolve conflict with the installation-cd-base module
  system.stateVersion = lib.mkForce "24.05";
}

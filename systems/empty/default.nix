{ lib, ... }:

{
  # Disable GRUB in the VM, because we boot directly, without a bootloader.
  boot.loader.grub.enable = false;
  custom.common.setup-grub.enable = false;

  # Disable tailscale for tests
  custom.common.tailscale.enable = false;

  # Wireless won't work in the VM.
  networking.wireless.enable = lib.mkForce false;
  services.connman.enable = lib.mkForce false;

  # Speed up booting by not waiting for ARP.
  networking.dhcpcd.extraConfig = "noarp";

  # Enable the QEMU guest agent.
  services.qemuGuest.enable = true;

  # Don't run ntpd in the guest. It should get the correct time from KVM.
  services.timesyncd.enable = false;

  meta.ip = "10.190.0.4";
  networking.hostName = "empty";
}

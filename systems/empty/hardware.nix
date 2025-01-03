{ pkgs, ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Remote filesystems
  fileSystems."/nix/.ro-store" = {
    device = "nix-store";
    fsType = "9p";
    neededForBoot = true;
    options = [
      "trans=virtio"
      "version=9p2000.L"
      "msize=16384"
      "x-systemd.requires=modprobe@9pnet_virtio.service"
      "cache=loose"
    ];
  };
  fileSystems."/age" = {
    device = "age";
    fsType = "9p";
    neededForBoot = true;
    options = [
      "trans=virtio"
      "version=9p2000.L"
      "msize=16384"
      "x-systemd.requires=modprobe@9pnet_virtio.service"
    ];
  };

  # Overlay filesystem for /nix/store, uniting the remote and local nix stores
  # If file is not found locally, it will be fetched from the remote store
  # Write operations are stored in tmpfs
  fileSystems."/nix/store" = {
    overlay = {
      lowerdir = [ "/nix/.ro-store" ];
      upperdir = "/var/lib/nixos/rw-store/upper";
      workdir = "/var/lib/nixos/rw-store/work";
    };
  };

  swapDevices = [ ];
}

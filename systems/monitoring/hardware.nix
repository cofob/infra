{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/c672d035-0a94-41b2-9c70-13a56a90411a";
    fsType = "ext4";
  };

  swapDevices = [ ];
}

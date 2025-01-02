{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/16bb5d77-d29f-4a36-bdc2-686ae973a6bb";
    fsType = "ext4";
  };

  swapDevices = [ ];
}
